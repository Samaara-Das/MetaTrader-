//+------------------------------------------------------------------+
//|                double rsi hidden regular divergence with ema.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.00"
//EA LOGIC DESCRIPTION : rsi hidden divergence and 200 ema (optional) on htf for trend bias. 
//rsi regular divergence on ltf, below/above 200 ema( optional) and heikin ashi for entry. 
//zz low/high and breakeven sl, RR tp and fixed.

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

input string ____ = " "; //  


input string zz_param = " "; //Fill ZigZag Parameters
input int zz_arrow_depth = 12; //Depth
input int zz_arrow_deviation = 5; //Deviation
input int zz_arrow_backStep = 3; //Backstep

input string __ = " "; // " "

//param for ma
input string ma_param = " "; //EMA Parameters
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //EMA Applied Price
input ENUM_MA_METHOD ma_methodd = MODE_EMA; //EMA Method
input int ma_periodd = 200; //EMA Period

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool zigzag_sl = false; //Allow ZigZag based stoploss
input bool div_sl = false; //Allow Divergence based stoploss
input double pips_for_sl = 1; //Amount of pips to be added/subtracted from stoploss
input double Risk = 1; //Percentage of free margin to risk
input double breakeven_ratio = 1; // Breakeven Ratio
input double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price 
input bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
input bool tp_fixd = false; //Allow Fixed TakeProfit
input bool sl_fixd = false; //Allow Fixed StopLoss
input double risk_reward_tp = 2; //Risk to Reward Ratio 
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input bool allow_ma = false; //Allow MA in Entry Condition
input ENUM_TIMEFRAMES higher_timeframe = PERIOD_M5; //Timeframe for Divergence of higher timeframe
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Divergence of lower timeframe

int ma_handle, ma_handle2, div_handle, div_handle2;
double ma[], div_reg[], div_hid[], ma2[], low_of_hid_bull, high_of_hid_bear, high_of_reg_bear, low_of_reg_bull;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime hid_bull_div_time, hid_bear_div_time, reg_bull_div_time, reg_bear_div_time, trade_close_time, hid_bear_div_curr_time, hid_bull_div_curr_time;
bool trade_check, trade_check2;

void OnDeinit(const int reason)
{

   IndicatorRelease(ma_handle);
   
}

void OnTick()
{

   ma_handle = iMA(_Symbol, lower_timeframe, ma_periodd, 0, ma_methodd, ma_appliedprice);
   ma_handle2 = iMA(_Symbol, higher_timeframe, ma_periodd, 0, ma_methodd, ma_appliedprice);
   
   MqlTick latest_price;
   MqlTradeRequest mrequest;
   MqlTradeResult mresult;
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   SymbolInfoTick(_Symbol, latest_price);
  
   CopyBuffer(ma_handle, 0, 1, 1, ma);
   ArraySetAsSeries(ma, true);
   CopyBuffer(ma_handle2, 0, 0, 1, ma2);
   ArraySetAsSeries(ma2, true);
   
   double candle[], open[], low[], high[];
   int hkn_ashi_handle = iCustom(_Symbol, lower_timeframe, "Heiken_Ashi");
   CopyBuffer(hkn_ashi_handle, 4, 1, 1, candle);  //0 for blue candles and 1 for red candles
   CopyBuffer(hkn_ashi_handle, 2, 1, 1, low);  //low
   CopyBuffer(hkn_ashi_handle, 1, 1, 1, high);  //high
   CopyBuffer(hkn_ashi_handle, 0, 1, 1, open);  //open
   
   int zz_handle = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth,zz_arrow_deviation,zz_arrow_backStep);
   double zz_high[], zz_low[], zz_col[];
   CopyBuffer(zz_handle, 1, 0, 301, zz_high);
   CopyBuffer(zz_handle, 2, 0, 301, zz_low);
   CopyBuffer(zz_handle, 0, 0, 301, zz_col);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true);
   ArraySetAsSeries(zz_col, true);
   
   int zz_handle2 = iCustom(_Symbol,higher_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth,zz_arrow_deviation,zz_arrow_backStep);
   double zz_high2[], zz_low2[], zz_col2[];
   CopyBuffer(zz_handle2, 1, 0, 301, zz_high2);
   CopyBuffer(zz_handle2, 2, 0, 301, zz_low2);
   CopyBuffer(zz_handle2, 0, 0, 301, zz_col2);
   ArraySetAsSeries(zz_high2, true);
   ArraySetAsSeries(zz_low2, true);
   ArraySetAsSeries(zz_col2, true);
  
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   double secondzigzagup=0;
   double secondzigzagup2=0;
   double secondzigzagdown=0;
   double secondzigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
   datetime secondzigzagdowntime=NULL,secondzigzagdowntime2=NULL;
   datetime secondzigzaguptime = NULL,secondzigzaguptime2 = NULL;
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   
   double zigzagup1=0;
   double zigzagup21=0;
   double zigzagdown1=0;
   double zigzagdown21=0;
   double secondzigzagup1=0;
   double secondzigzagup21=0;
   double secondzigzagdown1=0;
   double secondzigzagdown21=0;
   datetime zigzagdowntime1=NULL,zigzagdowntime21=NULL;
   datetime zigzaguptime1 = NULL,zigzaguptime21 = NULL;
   datetime secondzigzagdowntime1=NULL,secondzigzagdowntime21=NULL;
   datetime secondzigzaguptime1 = NULL,secondzigzaguptime21 = NULL;
   int two_up1=0,two_down1=0,second_two_up1=0,second_two_down1=0;
   
   
   for(int i= 1 ; i<100; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(_Symbol,lower_timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         break;
        }
     }
   for(int i= two_down+1 ; i<200; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }

   for(int i= 1 ; i<100; i++)
     {
      double uparrow=zz_low[i]; //down val
      double zero=zz_col[i];
      if(uparrow>0 && zero > 0)
        {

         zigzaguptime = iTime(_Symbol,lower_timeframe,i);
         zigzagup = uparrow;
         two_up = i;
         break;

        }
     }
   for(int i=  two_up+1 ; i<200; i++)
     {
      double uparrow=zz_low[i]; //down val
      double zero=zz_col[i];
      if(uparrow>0 && zero > 0)
        {
         zigzaguptime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     }
     
     //--------------------------------------------- hidden divergence zigzag
     
   for(int i= 1 ; i<100; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime1 = iTime(_Symbol,higher_timeframe,i);
         zigzagdown1 = downarrow;
         two_down1 = i;
         break;
        }
     }
   for(int i= two_down1+1 ; i<200; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime21 = iTime(_Symbol,higher_timeframe,i);
         zigzagdown21 = downarrow;
         break;
        }
     }

   for(int i= 1 ; i<100; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {

         zigzaguptime1 = iTime(_Symbol,higher_timeframe,i);
         zigzagup1 = uparrow;
         two_up1 = i;
         break;

        }
     }
   for(int i=  two_up1+1 ; i<200; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {
         zigzaguptime21 = iTime(_Symbol,higher_timeframe,i);
         zigzagup21 = uparrow;
         break;
        }
     }
     
     


    if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime) //regular bearish
     {
         int to = iBarShift(_Symbol,lower_timeframe,zigzaguptime2);
         int from = iBarShift(_Symbol,lower_timeframe,zigzagdowntime2);
         double first_rsi = maxRSIValue(from, to, lower_timeframe);
         datetime first_rsi_time = maxRSITime(from, to, lower_timeframe);
         int to2 = iBarShift(_Symbol,lower_timeframe,zigzaguptime);
         int from2 = iBarShift(_Symbol,lower_timeframe,zigzagdowntime);
         double second_rsi = maxRSIValue(from2, to2, lower_timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, lower_timeframe);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",clrRed);
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",clrRed);
             
            reg_bear_div_time = iTime(_Symbol, lower_timeframe, iBarShift(_Symbol, lower_timeframe, zigzagdowntime));
            high_of_reg_bear = zigzagdown;
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2) //regular bullish
     {       
         int to = iBarShift(_Symbol,lower_timeframe,zigzagdowntime2);
         int from = iBarShift(_Symbol,lower_timeframe,zigzaguptime2);
         double first_rsi = minRSIValue(from, to, lower_timeframe);
         datetime first_rsi_time = minRSITime(from, to, lower_timeframe);
         int to2 = iBarShift(_Symbol,lower_timeframe,zigzagdowntime);
         int from2 = iBarShift(_Symbol,lower_timeframe,zigzaguptime);
         double second_rsi = minRSIValue(from2, to2, lower_timeframe);
         datetime second_rsi_time = minRSITime(from2, to2, lower_timeframe);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",clrLawnGreen);
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",clrLawnGreen);
            
            reg_bull_div_time = iTime(_Symbol, lower_timeframe, iBarShift(_Symbol, lower_timeframe, zigzaguptime));
            low_of_reg_bull = zigzagup;
         }
     }
     
   if(zigzagdown1 < zigzagdown21  && zigzaguptime1 < zigzagdowntime1) //hidden bearish
   {
         int to = iBarShift(_Symbol,higher_timeframe,zigzaguptime21);
         int from = iBarShift(_Symbol,higher_timeframe,zigzagdowntime21);
         double first_rsi = maxRSIValue(from , to, higher_timeframe);
         datetime first_rsi_time = maxRSITime(from , to, higher_timeframe);
         int to2 = iBarShift(_Symbol,higher_timeframe,zigzaguptime1);
         int from2 = iBarShift(_Symbol,higher_timeframe,zigzagdowntime1);
         double second_rsi = maxRSIValue(from2 , to2, higher_timeframe);
         datetime second_rsi_time = maxRSITime(from2 , to2, higher_timeframe);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzaguptime21,zigzagup21,zigzagdowntime21,zigzagdown21,"firstReversal1",clrMaroon);  
            TrendCreate(zigzaguptime1,zigzagup1,zigzagdowntime1,zigzagdown1,"firstReversal2",clrMaroon);  
          
            hid_bear_div_time = iTime(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, zigzagdowntime21));
            hid_bear_div_curr_time = iTime(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, zigzagdowntime1));
            high_of_hid_bear = zigzagdown1;
         }
   }
   
   if(zigzaguptime1 > zigzagdowntime1 && zigzagup1 > zigzagup21) //hidden bullish
   {
         int to = iBarShift(_Symbol,higher_timeframe,zigzagdowntime21);
         int from = iBarShift(_Symbol,higher_timeframe,zigzaguptime21);
         double first_rsi = minRSIValue(from , to, higher_timeframe);
         datetime first_rsi_time = minRSITime(from , to, higher_timeframe);
         int to2 = iBarShift(_Symbol,higher_timeframe,zigzagdowntime1);
         int from2 = iBarShift(_Symbol,higher_timeframe,zigzaguptime1);
         double second_rsi = minRSIValue(from2 , to2, higher_timeframe);
         datetime second_rsi_time = minRSITime(from2 , to2, higher_timeframe);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzagdowntime21,zigzagdown21,zigzaguptime21,zigzagup21,"firstReversal1",clrGreen);  
            TrendCreate(zigzagdowntime1,zigzagdown1,zigzaguptime1,zigzagup1,"firstReversal2",clrGreen);     
        
            hid_bull_div_time = iTime(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, zigzaguptime21));
            hid_bull_div_curr_time = iTime(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, zigzaguptime1));
            low_of_hid_bull = zigzagup1;
         }
   }
     
   
   if (trade_check2 == true && PositionSelect(_Symbol) == false)
   {
   trade_check2 = false;
   trade_close_time = iTime(_Symbol, lower_timeframe, 1);
   }
   
   
   double high3 = 0.0;
   for(int i = 1; i <= iBarShift(_Symbol, higher_timeframe, hid_bear_div_curr_time); i++)
   {
          
    if ( iHigh(_Symbol, higher_timeframe, i) >= high3 )
     {
     high3 = iHigh(_Symbol, higher_timeframe, i);
     }
   }
   
   datetime reg_high_time = 0;
   double high2 = 0.0;
   for(int i = 1; i <= iBarShift(_Symbol, lower_timeframe, reg_bear_div_time); i++)
   {
          
    if ( iHigh(_Symbol, lower_timeframe, i) >= high2 )
    {
    high2 = iHigh(_Symbol, lower_timeframe, i);
    reg_high_time = iTime(_Symbol, lower_timeframe, i);
    }
   }
   
   CopyBuffer(ma_handle2, 0, 0, iBarShift(_Symbol, higher_timeframe, hid_bear_div_curr_time), ma2);
   ArraySetAsSeries(ma2, true);
   
   bool ma_check = ((allow_ma == true && high[0] < ma[0] && ma2[ArraySize(ma2)-1] > high_of_hid_bear) || (allow_ma == false));
   
   if (hid_bear_div_curr_time <= reg_bear_div_time && PositionSelect(_Symbol) == false && high2 == high_of_reg_bear && high2 >= high_of_hid_bear && candle[0] == 1 && high[0] == open[0] && ma_check == true &&
       high2 <= iHigh(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bear_div_time)) && iTime(_Symbol, lower_timeframe, 1) >= reg_bear_div_time && trade_time != iTime(_Symbol, lower_timeframe, 0) && hid_bear_div_curr_time >= trade_close_time)
   {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
         
         int shift = iBarShift(_Symbol, lower_timeframe, reg_bear_div_time);
         
         double slt = div_sl ? iHigh(_Symbol, lower_timeframe, shift):zigzag_sl ? zigzagdown:sl_fixd ? mrequest.price + (_Point*(fixed_pips_sl*10)):0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt - mrequest.price)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = (Risk/100) * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         mrequest.sl = slt + (_Point*(pips_for_sl*10));
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits):tp_fixd ? mrequest.price - (_Point*(fixed_pips_tp*10)):0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bear_div_time = hid_bear_div_time;
           prev_reg_bear_div_time = reg_bear_div_time;
           Print("2nd high of reg div = ",high2,"  hid div 2nd high = ",high_of_hid_bear," time of hid div = ",hid_bear_div_curr_time,"");
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
   trade_check2 = true;
  
  
   if (trade_check == true && PositionSelect(_Symbol) == false)
   {
   trade_check = false;
   trade_close_time = iTime(_Symbol, lower_timeframe, 1);
   }
   
   
   double low2 =  iLow(_Symbol, lower_timeframe, 1);
   datetime reg_low_time = 0;
   for(int i = 1; i <= iBarShift(_Symbol, lower_timeframe, reg_bull_div_time); i++)
   {
    
     if ( iLow(_Symbol, lower_timeframe, i) <= low2 )
     {
     low2 = iLow(_Symbol, lower_timeframe, i);
     reg_low_time = iTime(_Symbol, lower_timeframe, i);
     }
   }
   
   double low3 =  iLow(_Symbol, lower_timeframe, 1);
   for(int i = 1; i <= iBarShift(_Symbol, lower_timeframe, hid_bull_div_curr_time); i++)  //this is for checking if the price ever crossed first high/low of hidden divergence
   {
    
     if ( iLow(_Symbol, lower_timeframe, i) <= low3 )
     {
     low3 = iLow(_Symbol, lower_timeframe, i);
     }
   }
   
   CopyBuffer(ma_handle2, 0, 0, iBarShift(_Symbol, higher_timeframe, hid_bull_div_curr_time), ma2);
   ArraySetAsSeries(ma2, true);
   
   bool ma_check2 = ((allow_ma == true && low[0] > ma[0] && ma2[ArraySize(ma2)-1] < low_of_hid_bull) || (allow_ma == false));
   
   if (hid_bull_div_curr_time <= reg_bull_div_time && PositionSelect(_Symbol) == false && low2 == low_of_reg_bull && low2 <= low_of_hid_bull && candle[0] == 0 && low[0] == open[0] && ma_check2 == true &&
       low2 >= iLow(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bull_div_time)) && iTime(_Symbol, lower_timeframe, 1) >= reg_bull_div_time && trade_time != iTime(_Symbol, lower_timeframe, 0) && hid_bull_div_curr_time >= trade_close_time)
   {
         mrequest.action = TRADE_ACTION_DEAL; 
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
         
         int shift = iBarShift(_Symbol, lower_timeframe, reg_bull_div_time);
         
         double slt = div_sl ? iLow(_Symbol, lower_timeframe, shift):zigzag_sl ? zigzagup:sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)):0;
         double pips = (mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = (Risk/100) * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
   
         mrequest.sl = slt - (_Point*(pips_for_sl*10));
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits):tp_fixd ? mrequest.price + (_Point*(fixed_pips_tp*10)):0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bull_div_time = reg_bull_div_time;
           prev_hid_bull_div_time = hid_bull_div_time;
           Print("hid div = ",hid_bull_div_curr_time,"  reg div = ",reg_bull_div_time,"  lowest in range of reg div = ",reg_low_time," ");
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   
   if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   trade_check = true;
   
   
  if ( PositionSelect(_Symbol) ) 
  {
    
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    if ( type == POSITION_TYPE_BUY )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         OrderSend(mrequest, mresult);
      }
    }
    
    
    if ( type == POSITION_TYPE_SELL )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         OrderSend(mrequest, mresult);
      } 
    }
    
    }
    
  }
   
   
}


/*buy conditions:
check if regular divergence comes at or after the time hidden divergence came
check if price had not crossed regular divergence's 2nd low

conditions to be added:
regular divergence's second low should be in between the price of hidden divergence's 2nd low and hidden divergence's 1st low

same goes for sell*/

//make sure to add breakeven pips to breakeven logic

double maxRSIValue(int from, int to, ENUM_TIMEFRAMES tf)
  {
   double max_first_rsi=0;
   int handle = iRSI(_Symbol, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(max_first_rsi < rsi[i])
         max_first_rsi = rsi[i];
     }
   return max_first_rsi;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime maxRSITime(int from, int to, ENUM_TIMEFRAMES tf)
  {
   double max_first_rsi=0;
   datetime maxtime=currentTime();
   int handle = iRSI(_Symbol, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(max_first_rsi < rsi[i])
        {
         max_first_rsi = rsi[i];
         maxtime = iTime(_Symbol,tf,i);
        }
     }
   return maxtime;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double minRSIValue(int from, int to, ENUM_TIMEFRAMES tf)
  {
   double min_first_rsi=45356443455;
   int handle = iRSI(_Symbol, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(min_first_rsi > rsi[i])
         min_first_rsi = rsi[i];
     }
   return min_first_rsi;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime minRSITime(int from, int to, ENUM_TIMEFRAMES tf)
  {
   double min_first_rsi=45356443455;
   datetime mintime= currentTime();
   int handle = iRSI(_Symbol, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(min_first_rsi > rsi[i])
        {
         min_first_rsi = rsi[i];
         mintime = iTime(_Symbol,tf,i);
        }
     }
   return mintime;
  }
