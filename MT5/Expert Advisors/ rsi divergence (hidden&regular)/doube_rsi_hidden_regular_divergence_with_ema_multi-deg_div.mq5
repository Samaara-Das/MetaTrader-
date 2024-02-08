//+------------------------------------------------------------------+
//|   doube_rsi_hidden_regular_divergence_with_ema_multi-deg_div.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"
//EA LOGIC DESCRIPTION : rsi hidden divergence and 200 ema (optional) on htf for trend bias. 
//rsi regular divergence on ltf, below/above 200 ema( optional) and heiken ashi candle for entry;
//zz low/high and breakeven sl, RR tp and fixed.
//uses multi degree divergence's
//nili aunty & papa said that we're not going to use this for martingale because its got too many conditions
//otherwise this ea is working, but i hv to fix the breakeven to make sure it checks for the trades in one symbol instead of all the symbols
//check other mtgl eas to see if there any change to be added to martingale or not

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

input string ____ = " "; //  

input string zz_param = " "; //Fill ZigZag Parameters
input int zz_arrow_depth = 12; //First Depth for Divergence
input int zz_arrow_deviation = 5; //First Deviation for Divergence
input int zz_arrow_backStep = 3; //First Backstep for Divergence
input bool use_zz = true; //Use First Zigzag for Divergence

input int zz_arrow_depth2 = 8; //Second Depth for Divergence
input int zz_arrow_deviation2 = 5; //Second Deviation for Divergence
input int zz_arrow_backStep2 = 3; //Second Backstep for Divergence
input bool use_zz2 = true; //Use Second Zigzag for Divergence

input int zz_arrow_depth3 = 3; //Third Depth for Divergence
input int zz_arrow_deviation3 = 2; //Third Depth for Divergence
input int zz_arrow_backStep3 = 2; //Third Depth for Divergence
input bool use_zz3 = false; //Use Third Zigzag for Divergence

input string __ = " "; // " "

//param for ma
input string ma_param = " "; //EMA Parameters
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //EMA Applied Price
input ENUM_MA_METHOD ma_methodd = MODE_EMA; //EMA Method
input int ma_periodd = 200; //EMA Period

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool sl_breakeven = false; //Allow SL to Move to Breakeven price
input bool zigzag_sl = false; //Allow ZigZag based stoploss
input bool tp_fixd = false; //Allow Fixed TakeProfit
input bool sl_fixd = false; //Allow Fixed StopLoss
input bool div_sl = false; //Allow Divergence based stoploss
input bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
input bool div_close = false; //Allow Divergence based closing
input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

input string blank = " "; //_

input double pips_for_sl = 1; //Amount of pips to be added/subtracted from stoploss
input double breakeven_ratio = 1; // Breakeven Ratio
input double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price 
input double risk_reward_tp = 2; //Risk to Reward Ratio 
input double mtgl_risk_reward_sl = 3; //sl for mtgl
input double mtgl_risk_reward_tp = 2; //tp for mtgl
input double mtgl_multiplier = 2; //Martingale Multiplier
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input bool allow_ma = false; //Allow MA in Entry Condition
input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES higher_timeframe = PERIOD_M5; //Timeframe for Divergence of higher timeframe
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Divergence of lower timeframe
input int start = 3; //Start Time of EA
input int end = 23; //End Time of EA

int ma_handle, ma_handle2, hkn_ashi_handle, zz_handle, zz_handle2, counter = 0, trade_close_shift;
double ma[], div_reg[], div_hid[], ma2[], low_of_hid_bull, high_of_hid_bear, high_of_reg_bear, low_of_reg_bull;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime hid_bull_div_time, hid_bear_div_time, reg_bull_div_time, reg_bear_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time;
double high3, low3;
bool trade_check = false;
datetime history_start = TimeCurrent();

void OnDeinit(const int reason)
{

   IndicatorRelease(ma_handle);
   IndicatorRelease(ma_handle2);
   IndicatorRelease(hkn_ashi_handle);
   IndicatorRelease(zz_handle);
   IndicatorRelease(zz_handle2);
   
}


void divergence(double& zigzagup, double& zigzagdown, double& zigzagup2, double& zigzagdown2, datetime& zigzaguptime, datetime& zigzagdowntime, datetime& zigzaguptime2, datetime& zigzagdowntime2, int depth, int deviation, 
                int backstep, ENUM_TIMEFRAMES tf, datetime& reg_bear_div_time_, datetime& reg_bull_div_time_, double& reg_bear_div_hi, double& reg_bull_div_lo, //for regular divergence
                datetime& hid_bear_div_time_, datetime& hid_bull_div_time_, double& hid_bear_div_hi, double& hid_bull_div_lo, datetime& hid_bear_div_time_curr_, datetime& hid_bull_div_time_curr_)  //for hidden divergence
{

   zz_handle = iCustom(_Symbol,tf,"\\Indicators\\Examples\\ZigZag.ex5",depth,deviation,backstep);
   double zz_high[], zz_low[], zz_col[];
   CopyBuffer(zz_handle, 1, 0, 301, zz_high);
   CopyBuffer(zz_handle, 2, 0, 301, zz_low);
   CopyBuffer(zz_handle, 0, 0, 301, zz_col);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true);
   ArraySetAsSeries(zz_col, true);
   
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= 1 ; i<100; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(_Symbol,tf,i);
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
         zigzagdowntime2 = iTime(_Symbol,tf,i);
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

         zigzaguptime = iTime(_Symbol,tf,i);
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
         zigzaguptime2 = iTime(_Symbol,tf,i);
         zigzagup2 = uparrow;
         break;
        }
     }
     
     
     if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime&& tf == lower_timeframe) //regular bearish
     {
         int to = iBarShift(_Symbol,tf,zigzaguptime2);
         int from = iBarShift(_Symbol,tf,zigzagdowntime2);
         double first_rsi = maxRSIValue(from, to, tf);
         datetime first_rsi_time = maxRSITime(from, to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzaguptime);
         int from2 = iBarShift(_Symbol,tf,zigzagdowntime);
         double second_rsi = maxRSIValue(from2, to2, tf);
         datetime second_rsi_time = maxRSITime(from2, to2, tf);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",clrRed);
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",clrRed);
            
            reg_bear_div_time_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzagdowntime));
            reg_bear_div_hi = zigzagdown;
            
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2&& tf == lower_timeframe) //regular bullish
     {       
         int to = iBarShift(_Symbol,tf,zigzagdowntime2);
         int from = iBarShift(_Symbol,tf,zigzaguptime2);
         double first_rsi = minRSIValue(from, to, tf);
         datetime first_rsi_time = minRSITime(from, to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzagdowntime);
         int from2 = iBarShift(_Symbol,tf,zigzaguptime);
         double second_rsi = minRSIValue(from2, to2, tf);
         datetime second_rsi_time = minRSITime(from2, to2, tf);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",clrLawnGreen);
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",clrLawnGreen);
            
            reg_bull_div_time_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzaguptime));
            reg_bull_div_lo = zigzagup;
         }
     }
     
   if(zigzagdown < zigzagdown2  && zigzaguptime < zigzagdowntime && tf == higher_timeframe) //hidden bearish
   {
         int to = iBarShift(_Symbol,tf,zigzaguptime2);
         int from = iBarShift(_Symbol,tf,zigzagdowntime2);
         double first_rsi = maxRSIValue(from , to, tf);
         datetime first_rsi_time = maxRSITime(from , to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzaguptime);
         int from2 = iBarShift(_Symbol,tf,zigzagdowntime);
         double second_rsi = maxRSIValue(from2 , to2, tf);
         datetime second_rsi_time = maxRSITime(from2 , to2, tf);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",clrMaroon);  
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",clrMaroon);  
          
            hid_bear_div_time_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzagdowntime2));
            hid_bear_div_time_curr_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzagdowntime));
            hid_bear_div_hi = zigzagdown;
         }
   }
   
   if(zigzaguptime > zigzagdowntime && zigzagup > zigzagup2 && tf == higher_timeframe) //hidden bullish
   {
         int to = iBarShift(_Symbol,tf,zigzagdowntime2);
         int from = iBarShift(_Symbol,tf,zigzaguptime2);
         double first_rsi = minRSIValue(from , to, tf);
         datetime first_rsi_time = minRSITime(from , to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzagdowntime);
         int from2 = iBarShift(_Symbol,tf,zigzaguptime);
         double second_rsi = minRSIValue(from2 , to2, tf);
         datetime second_rsi_time = minRSITime(from2 , to2, tf);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",clrGreen);  
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",clrGreen);     
        
            hid_bull_div_time_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzaguptime2));
            hid_bull_div_time_curr_ = iTime(_Symbol, tf, iBarShift(_Symbol, tf, zigzaguptime));
            hid_bull_div_lo = zigzagup;
         }
   }
   
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
   hkn_ashi_handle = iCustom(_Symbol, lower_timeframe, "Heiken_Ashi");
   CopyBuffer(hkn_ashi_handle, 4, 1, 1, candle);  //0 for blue candles and 1 for red candles
   CopyBuffer(hkn_ashi_handle, 2, 1, 1, low);  //low
   CopyBuffer(hkn_ashi_handle, 1, 1, 1, high);  //high
   CopyBuffer(hkn_ashi_handle, 0, 1, 1, open);  //open
  
   
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
   int two_up1=0,two_down1=0,second_two_up1=0,second_two_down1=0;
   
if (use_zz == true)   //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}

if (use_zz2 == true)  //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}
          
if (use_zz3 == true) //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}
     

if (use_zz == true)   //for hidden divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, higher_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}

if (use_zz2 == true)  //for hidden divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, higher_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}
          
if (use_zz3 == true) //for hidden divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, higher_timeframe, 
           reg_bear_div_time, reg_bull_div_time, high_of_reg_bear, low_of_reg_bull, hid_bear_div_time, hid_bull_div_time, high_of_hid_bear, low_of_hid_bull, hid_bear_div_curr_time, hid_bull_div_curr_time);
}

 
 
  if (PositionSelect(_Symbol) && martingale_exit1 == true)
  {
  ulong ticket = PositionGetTicket(return_pos(_Symbol));
  if (  (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= high3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL  )
  {
    setorder(POSITION_TYPE_BUY, _Symbol);
    //Print("sent buy order  high = ",high," ask = ",SymbolInfoDouble(_Symbol,SYMBOL_ASK),"");
  }
  
  if (  (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= low3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
  {
    setorder(POSITION_TYPE_SELL, _Symbol);
    //Print("sent buy order  low = ",low,"  bid = ",SymbolInfoDouble(_Symbol,SYMBOL_BID),"");
  }
  }
 
 
   if (trade_check == true && PositionSelect(_Symbol) == false)
   {
   trade_check = false;
   trade_close_shift = iTime(_Symbol, lower_timeframe, 0);
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
   
   //hid_bear_div_time = zigzagdowntime2
   //hid_bull_div_time = zigzaguptime2
   
   //high_of_hid_bear = zigzagdown
   //low_of_hid_bull = zigzagup
   
   //hid_bear_div_curr_time = zigzagdowntime
   //hid_bull_div_curr_time = zigzaguptime

   
   if (trade_close_shift <= hid_bear_div_curr_time && hid_bear_div_curr_time <= reg_bear_div_time && high2 == high_of_reg_bear && high2 >= high_of_hid_bear && candle[0] == 1 && high[0] == open[0] && ma_check == true && PositionSelect(_Symbol) == false && 
       high2 <= iHigh(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bear_div_time)) && iTime(_Symbol, lower_timeframe, 1) >= reg_bear_div_time && reg_bear_div_time != prev_reg_bear_div_time && hid_bear_div_curr_time != prev_hid_bear_div_time)
   {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
         
         int shift = iBarShift(_Symbol, lower_timeframe, reg_bear_div_time);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? iHigh(_Symbol, lower_timeframe, shift):zigzag_sl ? zigzagdown:sl_fixd ? mrequest.price + (_Point*(fixed_pips_sl*10)):0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > mrequest.price ? slt - mrequest.price:mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         if(martingale_exit2 == false) 
         Lots = use_inital_lots == true ? inital_lots:Lots; 
         
         if(counter >= 1 && istradeprofit(_Symbol) < 0 && martingale_exit2 == true)
         {
         Lots = lotsize(_Symbol);
         Print("last trade made loss ", istradeprofit(_Symbol));
         }
         
         if((counter == 0 || (counter >= 1 && istradeprofit(_Symbol) >= 0)) && martingale_exit2 == true)
         {
         Lots  = use_inital_lots == true ? inital_lots:Lots; 
         Print("last trade made profit ",istradeprofit(_Symbol),"  ",istradeprofit(_Symbol) >= 0,"");
         }
         
         mrequest.sl = slt != 0 ? slt + (_Point*(pips_for_sl*10)):0;
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits):tp_fixd ? mrequest.price - (_Point*(fixed_pips_tp*10)):0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         bool res = OrderSend(mrequest, mresult);
       
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bear_div_time = hid_bear_div_curr_time;
           prev_reg_bear_div_time = reg_bear_div_time;
           high3 = zigzagdown;
           low3 = mrequest.price;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print("2nd high of reg div = ",high2,"  hid div 2nd high = ",high_of_hid_bear," time of hid div = ",hid_bear_div_curr_time,"");
           trade_check = true;
           
           if(martingale_exit2 == true)
           counter++;
           
           if (  (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= high3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL  )
            {
              if(martingale_exit1 == true)
              setorder(POSITION_TYPE_BUY, _Symbol);
            }
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
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
   
   
   CopyBuffer(ma_handle2, 0, 0, iBarShift(_Symbol, higher_timeframe, hid_bull_div_curr_time), ma2);
   ArraySetAsSeries(ma2, true);
   
   bool ma_check2 = ((allow_ma == true && low[0] > ma[0] && ma2[ArraySize(ma2)-1] < low_of_hid_bull) || (allow_ma == false));
   
  // Print("cond 1 = ",trade_close_shift <= hid_bull_div_curr_time && hid_bull_div_curr_time <= reg_bull_div_time,"   cond 2 = ",low2 == low_of_reg_bull && low2 <= low_of_hid_bull,"   cond 3 = ",candle[0] == 0 && low[0] == open[0] && ma_check2 == true," ");
   //Print(" cond 4 = ",low2 >= iLow(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bull_div_time)),"   cond 5 = ",iTime(_Symbol, lower_timeframe, 1) >= reg_bull_div_time,"  cond 6 = ",reg_bull_div_time != prev_reg_bull_div_time && hid_bull_div_curr_time != prev_hid_bull_div_time,"");
   if (trade_close_shift <= hid_bull_div_curr_time && hid_bull_div_curr_time <= reg_bull_div_time && low2 == low_of_reg_bull && low2 <= low_of_hid_bull && candle[0] == 0 && low[0] == open[0] && ma_check2 == true && PositionSelect(_Symbol) == false &&
       low2 >= iLow(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bull_div_time)) && iTime(_Symbol, lower_timeframe, 1) >= reg_bull_div_time && reg_bull_div_time != prev_reg_bull_div_time && hid_bull_div_curr_time != prev_hid_bull_div_time)
   {
         mrequest.action = TRADE_ACTION_DEAL; 
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
         
         int shift = iBarShift(_Symbol, lower_timeframe, reg_bull_div_time);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? iLow(_Symbol, lower_timeframe, shift):zigzag_sl ? zigzagup:sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)):0;
         double pips = (mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         if(martingale_exit2 == false) 
         Lots = use_inital_lots == true ? inital_lots:Lots; 
         
         if(counter >= 1 && istradeprofit(_Symbol) < 0 && martingale_exit2 == true)
         {
         Lots = lotsize(_Symbol);
         Print("last trade made loss ", istradeprofit(_Symbol));
         }
         
         if((counter == 0 || (counter >= 1 && istradeprofit(_Symbol) >= 0)) && martingale_exit2 == true)
         {
         Lots  = use_inital_lots == true ? inital_lots:Lots; 
         Print("last trade made profit ",istradeprofit(_Symbol),"  ",istradeprofit(_Symbol) >= 0,"");
         } 
         
         mrequest.sl = slt != 0 ? slt - (_Point*(pips_for_sl*10)):0;
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits):tp_fixd ? mrequest.price + (_Point*(fixed_pips_tp*10)):0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bull_div_time = reg_bull_div_time;
           prev_hid_bull_div_time = hid_bull_div_curr_time;
           high3 = mrequest.price;
           low3 = zigzagup;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print("hid div = ",hid_bull_div_curr_time,"  reg div = ",reg_bull_div_time,"  lowest in range of reg div = ",reg_low_time," ");
           trade_check = true;
           
           if(martingale_exit2 == true)
           counter++;
           
            if (  (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= low3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
            {
              if(martingale_exit1 == true)
              setorder(POSITION_TYPE_SELL, _Symbol);
            }
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   
   
   
   if(PositionsTotal() > 0 && martingale_exit1 == true)
   {
     long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
      for(int i = HistoryDealsTotal()-1; i >= 0; i--)
       {
       ulong ticket = HistoryDealGetTicket(i);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       break;
       //Print("latest close = ",latest_close2,"  latest open = ",time_of_trade_open,"");
       }
       }
       
     }
     
     if(latest_close > trade_time) //check if most recent close time is greater than time_of_open_trade2, if so then close all open orders
     {
       close_all(_Symbol);
     }
       
   }
   
   //closing when total profit is 0 only when the breakeven exit is allowed
   if(breakeven_exit == true && PositionsTotal() >= trades_for_breakeven)  //this does not work properly, it has to know how many positions are in a symbol exactly and not take the total positions
   { 
     if(profit_total(_Symbol) >= 0)
     {
       close_all(_Symbol);
     }
   }
 
 
 
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
    ulong ticket = PositionGetTicket(i);
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    if ( type == POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == _Symbol )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         bool res = OrderSend(mrequest, mresult);
      }
      
      if ( div_close == true && PositionGetInteger(POSITION_TIME) <= reg_bear_div_time ) 
      {
         ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
         string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
         int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
         ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
         double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      
         ZeroMemory(mrequest);
         ZeroMemory(mresult);
         
         mrequest.action   =TRADE_ACTION_DEAL;        // type of trade operation
         mrequest.position =position_ticket;          // ticket of the position
         mrequest.symbol   =position_symbol;          // symbol 
         mrequest.volume   =volume;                   // volume of the position
         mrequest.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
         mrequest.type =ORDER_TYPE_SELL;
         bool res = OrderSend(mrequest, mresult);
      } 
    }
    
    
    if ( type == POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == _Symbol )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         bool res = OrderSend(mrequest, mresult);
      } 
      
   
      if ( div_close == true && PositionGetInteger(POSITION_TIME) <= reg_bull_div_time ) 
      {
         ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
         string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
         int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
         ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
         double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      
         ZeroMemory(mrequest);
         ZeroMemory(mresult);
         
         mrequest.action   =TRADE_ACTION_DEAL;        // type of trade operation
         mrequest.position =position_ticket;          // ticket of the position
         mrequest.symbol   =position_symbol;          // symbol 
         mrequest.volume   =volume;                   // volume of the position
         mrequest.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
         mrequest.type =ORDER_TYPE_BUY;
         bool res = OrderSend(mrequest, mresult);
      } 
    }
    
    
    }
   
}






void setorder(ENUM_POSITION_TYPE order_type, string symb) //sets pending orders with doubles lotsize and correct order type and entry price
{

  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);
  double pos_sl, pos_tp, entry_price;
  int count = 0;
  
     
      ulong  position_ticket=PositionGetTicket(return_pos(symb));
      long digits = SymbolInfoInteger(symb, SYMBOL_DIGITS);
      entry_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_BID), digits):NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_ASK), digits);                            
    
         pos_sl = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? PositionGetDouble(POSITION_TP):PositionGetDouble(POSITION_TP);   
         pos_tp = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? PositionGetDouble(POSITION_SL):PositionGetDouble(POSITION_SL);   
         
         request.action = TRADE_ACTION_DEAL;                                
         request.price = entry_price;
         request.sl = pos_sl;
         request.tp = pos_tp;
         request.symbol = symb;                                         
         request.volume = PositionGetDouble(POSITION_VOLUME)*mtgl_multiplier;                                            
         request.magic = 1;                                        
         request.type = order_type == POSITION_TYPE_BUY ? ORDER_TYPE_BUY:ORDER_TYPE_SELL;                                                
         request.type_filling = ORDER_FILLING_FOK;                        
         request.deviation=100;   
         
         bool res = OrderSend(request, result);
         
         if((result.retcode==10009) || (result.retcode==10008)) //Request is completed or order placed
         {
           for(int i = 0; i < PositionsTotal(); i++)
           {
           
             ulong ticket=PositionGetTicket(i);
             if(PositionGetString(POSITION_SYMBOL) == symb)
             count++;
            
           }
           
           if(count == 2)
           modify(symb);
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           close_all(symb);
           ResetLastError();
         }
 
  
} 

//modify
void modify(string symbol)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   double price1 = 0.0, price2 = 0.0, sl = 0.0, tp = 0.0;
   int pos1 = NULL, pos2 = NULL;
   long digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   
   for(int i = 0; i < PositionsTotal(); i++)
   {
   ulong ticket = PositionGetTicket(i);
   if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
   {
   price1 = PositionGetDouble(POSITION_PRICE_OPEN);
   pos1 = i;
   }
   
   if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
   {
   price2 = PositionGetDouble(POSITION_PRICE_OPEN);
   pos2 = i;
   }
   }
   
   double range = price1 > price2 ? price1 - price2 : price2 - price1; 
    
    for(int i = 0; i < 2; i++)
    {
        
         ulong ticket = i == 0 ? PositionGetTicket(pos1):PositionGetTicket(pos2);
         
         if(i == 0)
         { 
         sl = PositionGetDouble(POSITION_PRICE_OPEN)-NormalizeDouble((range*mtgl_risk_reward_sl), digits);
         tp = PositionGetDouble(POSITION_PRICE_OPEN)+NormalizeDouble((range*mtgl_risk_reward_tp), digits);  
         }                                                                                
         else
         {
         sl = PositionGetDouble(POSITION_PRICE_OPEN)+NormalizeDouble((range*mtgl_risk_reward_sl), digits);   
         tp = PositionGetDouble(POSITION_PRICE_OPEN)-NormalizeDouble((range*mtgl_risk_reward_tp), digits); 
         }                                                                                       
         
         request.action = TRADE_ACTION_SLTP; 
         request.position = ticket;   
         request.symbol = symbol;    
         request.sl = sl;              
         request.tp = tp;               
         
         bool res = OrderSend(request, result);
         
         if((result.retcode==10009) || (result.retcode==10008)) //Request is completed or order placed
         {
           if (i == 0)
           high3 = PositionGetDouble(POSITION_PRICE_OPEN);
           else
           low3 = PositionGetDouble(POSITION_PRICE_OPEN);
         }
         else 
         {
           Print("The modify order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
         
    }
  
}

int return_pos(string symbol)
{
  int pos = 0;
  datetime time = 0;
  for(int i = 0; i < PositionsTotal(); i++)
  {
   
      ulong ticket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_TIME) > time)
      pos = i;
    
  }
  
  return pos;
}

double profit_total(string symb)
{
  double profit = 0.0;
  for(int i = 0; i < PositionsTotal(); i++)
  {
    
     ulong ticket = PositionGetTicket(i);
     if(PositionGetSymbol(i) == symb)
     profit += PositionGetDouble(POSITION_PROFIT);
    
  }
  
  return profit;
}


void close_all(string symb)
{
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  
  for(int i = 0; i < PositionsTotal(); i++)
     {
         ulong ticket = PositionGetTicket(i);
         if(PositionGetString(POSITION_SYMBOL) == symb)
         {
         double entry_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_BID), _Digits):NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_ASK), _Digits);  
         ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
         string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
         ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
         double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
         
         ZeroMemory(mrequest);
         ZeroMemory(mresult);
         
         mrequest.action   =TRADE_ACTION_DEAL;        // type of trade operation
         mrequest.position =position_ticket;          // ticket of the position
         mrequest.symbol   =position_symbol;          // symbol 
         mrequest.volume   =volume;                   // volume of the position
         mrequest.price    =entry_price; 
         mrequest.type =PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? ORDER_TYPE_SELL:ORDER_TYPE_BUY; 
         bool res = OrderSend(mrequest, mresult);
         
         if((mresult.retcode==10009) || (mresult.retcode==10008)) //Request is completed or order placed
         {
         Print("closed trade successfully");
         trade_close_shift = Bars(symb, PERIOD_CURRENT) - 0;
         }
         else
         {
           Print("The closing order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
         }
     }
}


double istradeprofit(string symb)
{
 
  double check = 0;
  HistorySelect(history_start, TimeCurrent()+60*60*24);
  
       for(int i = HistoryDealsTotal()-1; i >= 0; i--)
       {
         ulong ticket = HistoryDealGetTicket(i);
         if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) && HistoryDealGetString(ticket, DEAL_SYMBOL) == symb) //this may or may not work because the last deal may/may not belong to the current symbol we're checking 
         {
              check = HistoryDealGetDouble(ticket, DEAL_PROFIT);
              break;
         }
       }

return check;
}

double lotsize(string symb)
{

   double lot = 0.0;
   HistorySelect(history_start, TimeCurrent()+60*60*24);
    
       for(int i = HistoryDealsTotal()-1; i >= 0; i--)
       {
         ulong ticket = HistoryDealGetTicket(i);
         if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) && HistoryDealGetString(ticket, DEAL_SYMBOL) == symb) //this may or may not work because the last deal may/may not belong to the current symbol we're checking 
         {
           lot = HistoryDealGetDouble(ticket, DEAL_VOLUME)*2;
           break; 
         }
       }
     
     return lot;
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
