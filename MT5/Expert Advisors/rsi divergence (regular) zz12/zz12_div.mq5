//+------------------------------------------------------------------+
//|                                                     zz12_div.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"

//EA description: rsi regular/hidden divergence and then zigzag 12 pattern break
//added first zz high/low based sl. this puts the sl at the zz high/low previous to the latest one
//added zz4_shift for the shift to start looking for zz high/lows for sl and mtgl1 to avoid putting sl at
//zz high/low which is at shift 0


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
input bool use_zz3 = true; //Use Third Zigzag for Divergence

input int zz_arrow_depth4 = 3; //Fourth Depth for Zigzag 1-2 entry
input int zz_arrow_deviation4 = 2; //Fourth Deviation for Zigzag 1-2 entry
input int zz_arrow_backStep4 = 2; //Fourth Backstep for Zigzag 1-2 entry
input int zz4_shift = 1; //Fourth ZigZag Shift (shift to start looking for zz highs/lows for sl)

input string blank2 = " "; //_

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool sl_breakeven = false; //Allow SL to Move to Breakeven price
input bool zigzag_sl = false; //Allow ZigZag based stoploss
input bool first_hi_low = false; //Allow SL to be 1st ZZ high/low Based
input bool tp_fixd = false; //Allow Fixed TakeProfit
input bool sl_fixd = false; //Allow Fixed StopLoss
input bool div_sl = false; //Allow Divergence based stoploss
input bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
input bool first_trade_exit = false; //First Trade Exit (1:1 risk-reward)
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
input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int start = 3; //Start Time of EA
input int end = 23; //End Time of EA

int zz_handle, zz_handle2, counter = 0;
datetime trade_close_shift, reg_bear_lp, reg_bull_lp;
double div_reg[], div_hid[], low_of_reg_bull, high_of_reg_bear, low_of_reg_bull2, high_of_reg_bear2;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime reg_bull_div_time, reg_bear_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time;
double high3, low3;
bool trade_check = false;
datetime history_start = TimeCurrent();

int OnInit(void)
{
  zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
  return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

   IndicatorRelease(zz_handle);
   IndicatorRelease(zz_handle2);
   
}


void divergence(double& zigzagup, double& zigzagdown, double& zigzagup2, double& zigzagdown2, datetime& zigzaguptime, datetime& zigzagdowntime, datetime& zigzaguptime2, datetime& zigzagdowntime2, 
                int depth, int deviation, int backstep, ENUM_TIMEFRAMES tf, //for zz settings and timeframe
                double& reg_bear_div_hi, double& reg_bull_div_lo, double& reg_bear_div_hi2, double& reg_bull_div_lo2,
                datetime& reg_bear_div_time_, datetime& reg_bull_div_time_, datetime& reg_bear_div_time_curr_, datetime& reg_bull_div_time_curr_, datetime& reg_bull_lp_, datetime& reg_bear_lp_) 
{

   zz_handle = iCustom(_Symbol,tf,"\\Indicators\\Examples\\ZigZag.ex5",depth,deviation,backstep);
   double zz_high[], zz_low[], zz_col[];
   CopyBuffer(zz_handle, 1, 0, 100, zz_high);
   CopyBuffer(zz_handle, 2, 0, 100, zz_low);
   CopyBuffer(zz_handle, 0, 0, 100, zz_col);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true);
   ArraySetAsSeries(zz_col, true);
   
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= 1 ; i<50; i++)
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
   for(int i= two_down+1 ; i<50; i++)
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

   for(int i= 1 ; i<50; i++)
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
   for(int i=  two_up+1 ; i<50; i++)
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
     
     
     if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime) //regular bearish
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
            
            reg_bear_div_time_ = zigzagdowntime2;
            reg_bear_div_time_curr_ = zigzagdowntime;
            reg_bear_div_hi = zigzagdown2;
            reg_bear_div_hi2 = zigzagdown;
            reg_bear_lp_ = zigzaguptime2;
            
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2) //regular bullish
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
            
            reg_bull_div_time_ = zigzaguptime2;
            reg_bull_div_time_curr_ = zigzaguptime;
            reg_bull_div_lo = zigzagup2;
            reg_bull_div_lo2 = zigzagup;
            reg_bull_lp_ = zigzagdowntime2;
         }
     }
 
   
}


void OnTick()
{

   MqlTick latest_price;
   MqlTradeRequest mrequest;
   MqlTradeResult mresult;
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   SymbolInfoTick(_Symbol, latest_price);
   MqlDateTime date;
   TimeCurrent(date);
   MqlDateTime date2;
   
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
           high_of_reg_bear, low_of_reg_bull, high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp);
}

if (use_zz2 == true)  //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, 
           high_of_reg_bear, low_of_reg_bull, high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp);
}
          
if (use_zz3 == true) //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, 
           high_of_reg_bear, low_of_reg_bull, high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp);
}
     

   zigzagup=0;
   zigzagup2=0;
   zigzagdown=0;
   zigzagdown2=0;
   zigzagdowntime=NULL;zigzagdowntime2=NULL;
   zigzaguptime = NULL;zigzaguptime2 = NULL;
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
 
  //zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
  double zz_high2[], zz_low2[], zz_col2[];
  CopyBuffer(zz_handle2, 1, 0, 100, zz_high2);
  CopyBuffer(zz_handle2, 2, 0, 100, zz_low2);
  CopyBuffer(zz_handle2, 0, 0, 100, zz_col2);
  ArraySetAsSeries(zz_high2, true);
  ArraySetAsSeries(zz_low2, true);
  ArraySetAsSeries(zz_col2, true);
  
   for(int i= 0 ; i<50; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(_Symbol,lower_timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         //Print("found zz down time = ",zigzagdowntime," on shift ",i,"");
         break;
        }
     }
   for(int i= two_down+1 ; i<50; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }
 
   for(int i= 0 ; i<50; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {

         zigzaguptime = iTime(_Symbol,lower_timeframe,i);
         zigzagup = uparrow;
         two_up = i;
         break;

        }
     }
   for(int i=  two_up+1 ; i<50; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {
         zigzaguptime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     } 
     
     
   //for sl only
   double _zigzagup=0;
   double _zigzagup2=0;
   double _zigzagdown=0;
   double _zigzagdown2=0;
   datetime _zigzagdowntime=NULL;datetime _zigzagdowntime2=NULL;
   datetime _zigzaguptime = NULL;datetime _zigzaguptime2 = NULL;
   int _two_up=0,_two_down=0,_second_two_up=0,_second_two_down=0;
 
   for(int i= zz4_shift ; i<50; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         _zigzagdowntime = iTime(_Symbol,lower_timeframe,i);
         _zigzagdown = downarrow;
         _two_down = i;
         //Print("found zz down time = ",zigzagdowntime," on shift ",i,"");
         break;
        }
     }
   for(int i= two_down+1 ; i<50; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         _zigzagdowntime2 = iTime(_Symbol,lower_timeframe,i);
         _zigzagdown2 = downarrow;
         break;
        }
     }

   for(int i= zz4_shift ; i<50; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {

         _zigzaguptime = iTime(_Symbol,lower_timeframe,i);
         _zigzagup = uparrow;
         _two_up = i;
         break;

        }
     }
   for(int i=  two_up+1 ; i<50; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {
         _zigzaguptime2 = iTime(_Symbol,lower_timeframe,i);
         _zigzagup2 = uparrow;
         break;
        }           
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
   
   
   int highest_ind1 = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, reg_bear_div_curr_time), 1);
   double highest1 = iHigh(_Symbol, lower_timeframe, highest_ind1);
   
   
   //Print(" ",trade_close_shift,"  ",reg_bear_lp,"  cond1 =",trade_close_shift <= reg_bear_lp,"  cond2 = ",reg_bear_div_time != 0,"  cond3 = ",reg_bear_div_time != prev_reg_bear_div_time,"  cond4 = ",highest1 == high_of_reg_bear2,"  cond5 = ",((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2)),"");
   if(trade_close_shift <= reg_bear_lp && reg_bear_div_time != 0 && PositionSelect(_Symbol) == false && reg_bear_div_time != prev_reg_bear_div_time && highest1 == high_of_reg_bear2 && zigzagdowntime2 >= reg_bear_div_curr_time && 
      ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2)) )
   {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? high_of_reg_bear2 : zigzag_sl ? _zigzagdown : sl_fixd ? mrequest.price + (_Point*(fixed_pips_sl*10)) : first_hi_low ? _zigzagdown2 : first_trade_exit ? 0:0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
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
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : tp_fixd ? mrequest.price - (_Point*(fixed_pips_tp*10)) : first_trade_exit ? mrequest.price - (zigzagdown-mrequest.price) : 0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         if(date.hour >= start && date.hour < end)
         bool res = OrderSend(mrequest, mresult);
       
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           history_start = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bear_div_time = reg_bear_div_time;
           high3 = zigzagdown;
           low3 = mrequest.price;
           trade_check = true;
           
           if(martingale_exit2 == true)
           counter++;
           
           ulong ticket = PositionGetTicket(return_pos(_Symbol));
           if (  (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= high3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && martingale_exit1 == true )
           setorder(POSITION_TYPE_BUY, _Symbol);
          
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   

   int lowest_ind1 = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, reg_bull_div_curr_time), 1);
   double lowest1 = iLow(_Symbol, lower_timeframe, lowest_ind1);
   
   
   //Print("cond1 = ",trade_close_shift <= reg_bull_lp,"  cond2 = ",reg_bull_div_time != 0,"  cond3 = ",reg_bull_div_time != prev_reg_bull_div_time,"  cond4 = ",lowest1 == low_of_reg_bull2,"  cond5 = ",((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2)),"");
   if (trade_close_shift <= reg_bull_lp && reg_bull_div_time != 0 && PositionSelect(_Symbol) == false && reg_bull_div_time != prev_reg_bull_div_time && lowest1 == low_of_reg_bull2 && zigzaguptime2 >= reg_bull_div_curr_time && 
       ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2)) )
   {
         mrequest.action = TRADE_ACTION_DEAL; 
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
        
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? low_of_reg_bull2 : zigzag_sl ? _zigzagup : sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)) : first_hi_low ? _zigzagup2 : first_trade_exit ? 0 : 0;
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
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : tp_fixd ? mrequest.price + (_Point*(fixed_pips_tp*10)) : first_trade_exit ? mrequest.price + (mrequest.price-zigzagup) : 0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
          
         if(date.hour >= start && date.hour < end)
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           history_start = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bull_div_time = reg_bull_div_time;
           high3 = mrequest.price;
           low3 = zigzagup;
           trade_check = true;
           
           if(martingale_exit2 == true)
           counter++;
           
            ulong ticket = PositionGetTicket(return_pos(_Symbol));
            if (  (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= low3) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && martingale_exit1 == true )
            setorder(POSITION_TYPE_SELL, _Symbol);

         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   
   
int count = 0;  
for(int i = 0; i < PositionsTotal(); i++)
{ 
  ulong ticket=PositionGetTicket(i);
  if(PositionGetString(POSITION_SYMBOL) == _Symbol)
  count++;
            
} 
   
   if(count > 0 && martingale_exit1 == true)
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
   if(breakeven_exit == true && count >= trades_for_breakeven)  //this does not work properly, it has to know how many positions are in a symbol exactly and not take the total positions
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
      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         bool res = OrderSend(mrequest, mresult);
      }
      
    }
    
    
    if ( type == POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == _Symbol )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
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
       
           if(close_trades == true)
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
  
  
//do a check to make sure that this is the first time the ea is running using a bool variable          
//if it is the first time, run a loop to check for 4 points of zz pattern

//if it isnt and zigzag value of current bar != 0, replace  variable which holds zigzagdown2/zigzagup2 value with zigzagup/zigzagdown
//zigzagdown2/zigzagup2

//------- logic for calculating latest 4 zz points

//1. calculate all 4 zz points at the start of ea 
//2. get all those point's time

// 3. update the latest zz point when there is a zz high/zz low val on shift 0 and it is not equal to the latest zz point
// 4. if there is a zz value on shift 0 and its type is not equal to the latest zz point's type, 
// 
