#property copyright 
#property link      "https://www.mql5.com"
#property version   "13.00"
//EA LOGIC description : 200 and 50 ema buy/sell cross (trend bias), price outside the both bb and then closing inside one of the bbs, 
//div/rsi to be there (optional) and entry when heikin ashi buy/sell candle or zigzag 1-2 break pattern. closing with div / RR/ fixed/ bb. 
//stop loss as per look back bars (to find the highest/lowest). 
//rsi with zigzag divergence logic used in the ea for divergence & multipile divergences are used
//fixed pip sl added nad heiken ashi removed with martingale option
//added a different kind of martingale which increases lotsize if last trade was a loss & resets to initial lotsize if last trade was a profit.
//added first zz high/low based sl. this puts the sl at the zz high/low previous to the latest one
//added zz4_shift for zz based sl so that, it will start looking for highs/lows before shift 1

//note: this ea is the previous version of the "bb_ema_zz12_mtgl (not working)" ea. that ea has made bb and ma optional, but this has not. that ea
//is unfinished but this is finished.

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

//parameters for ema
input string latest8Heiken;
input string ma_param = " ";  //Fill Moving Average Parameters Below
input int slowmaperiod = 200; //Slow Moving Average Period
input int fastmaperiod = 50;  //Fast Moving Average Period
input ENUM_MA_METHOD mamethod = MODE_EMA; //MA Method
input ENUM_APPLIED_PRICE appliedprice = PRICE_CLOSE; //Applied MA Price

input string ___ = " "; //   _

//parameters for bb
input string bb_param = " ";  //Fill Bollinger Bands Parameters Below
input int bbmaperiod = 20;    //First Bollinger Bands MA Period
input double bb_dev = 2.0;    //Deviation for First Bollinger Band
input ENUM_APPLIED_PRICE bbappliedprice = PRICE_CLOSE; //Applied First Bollinger Band Price
input int bbmaperiod2 = 20;    //Second Bollinger Bands MA Period
input double bb_dev2 = 2.0;    //Deviation for Second Bollinger Band
input ENUM_APPLIED_PRICE bbappliedprice2 = PRICE_CLOSE; //Applied Second Bollinger Band Price

input string ____ = " "; //  _

//parameters for rsi
input string rsi_param = " ";  //Fill RSI Parameters Below
input ENUM_APPLIED_PRICE rsi_appliedprice = PRICE_CLOSE; //Applied Price for RSI
input int rsi_period = 14; //Period for RSi
input double rsi_ob_lev = 70; //RSI Overbought Level
input double rsi_os_lev = 30; //RSI Oversold Level

input string _ = " "; //  _

//parameters for stdDev
string stddev_param = " "; //Fill StdDev Parameters Below
 int std_period = 20; //StdDev Period
ENUM_APPLIED_PRICE std_appliedprice = PRICE_CLOSE; //StdDev Applied price
 ENUM_MA_METHOD std_method = MODE_SMA; //StdDev Ma Method

input string hh = " "; // -

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

input int zz_arrow_depth4 = 3; //Fourth Depth for Zigzag 1-2 entry
input int zz_arrow_deviation4 = 2; //Fourth Deviation for Zigzag 1-2 entry
input int zz_arrow_backStep4 = 2; //Fourth Backstep for Zigzag 1-2 entry
input int zz4_shift = 1; //Fourth ZigZag Shift (shift to start looking for zz highs/lows)

input string _____ = " "; //  " "

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input string entry = " "; //Fill Entry Conditions
input bool allow_div_in_entry = false; //Allow Divergence Based Entry
bool allow_std_dev_in_entry = true; //Allow StdDev Based Entry
input bool allow_rsi_in_entry = false; //Allow Rsi Oversold/UnderBought Based Entry
input bool allow_any_one_entry = false; //Allow Any one of the above 2 options
input bool allow_zigzag_entry = true; //Allow Zigzag 1-2 break Based entry
input bool allow_ma_in_entry = true; //Allow MA in Entry

input string ff = " "; // _
input string close = " "; //Fill Closing Conditions
input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
input bool allow_risk_reward_based_close = false; //Allow Risk-Reward Based Closing
input bool allow_div_based_close = false; //Allow Divergence Based Closing
input bool allow_outer_band_cross_close = false; //Allow Outer Band Cross Based Closing
input bool first_trade_exit = false; //First Trade Exit
input double breakeven_ratio = 1; //Break Even Ratio
input double breakeven_pips = 2; //Pips to Be Added/Subtracted from Breakeven price
input bool allow_breakeven_sl = false; //Allow sl to be Breakeven Price
input bool fixed_tp = false; // Fixed Takeprofit
input bool fixed_sl = false; // Fixed StopLoss
input bool swing_hi_lo = true; // LookBack bar based stoploss
input bool zz_swing = false; // ZigZag Swing high/low Based StopLoss
input bool zz_first = false; // First ZZ Leg High/Low Based Stoploss

input string tg = " "; // _

input int lookback = 8;  //LookBack For Finding Highest/Lowest bar before Candle outside band
input int range_for_candle_outside = 6; //Lookback for Finding Candle outside of band 

int std_bar_range = 10; //Bar Range for StdDev
input double fixed_tp_pips = 10; //Fixed Takeprofit pips
input double fixed_sl_pips = 50; //Fixed Stoploss pips
input double risk_reward_tp = 2; //Risk to Reward Ratio
input double mtgl_risk_reward_sl = 3; //mtgl sl
input double mtgl_risk_reward_tp = 2; //mtgl tp
input double mtgl_multiplier = 2; //Martingale Multiplier

input bool single_trade = true; //Single Trade
input bool multi_trade = false; //Multi Trade
input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

bool candle_out_of_both = true; //Candle Outside of Both Bollinger Bands
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // Free margin percentage you want to risk for the trade
input double inital_lots = 0.01; //Initial Lots
input ENUM_TIMEFRAMES timeframe = PERIOD_M5; //Timeframe for Divergence Close Condition 
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int start = 4; //Start Time
input int end = 23; //End Time

//handles & indicator buffer arrays
int bb_handle, bb_handle2, maslowhandle, mafasthandle, div_handle; 
int rsi_handle, std_handle, hkn_ashi_handle;
double maslow[], mafast[], bb_upper[], bb_lower[], rsi_val[], rsi_val2[];
double bb_lower2[], bb_upper2[], std_val[], std_val2[], hkn_ashi_val[];
double hkn_ashi_close[], hkn_ashi_low[], hkn_ashi_high[];

ENUM_TIMEFRAMES pos_tf = lower_timeframe;
int prev_bb_bar_sell_sig = 0, shift_of_candle_inside2 = 0, zigzag_high_time, prev_bb_bar_sell_sig1 = 0, prev_bb_bar_buy_sig1 = 0;
int zigzag_high_time1 = 0, zigzag_low_time1 = 0, trade_close_shift = 0, counter = 0;
double pos_tp, pos_sl, bb_buy_low, bb_sell_high, zigzag_low = 0.0, zigzag_high = 0.0;
int time_of_trade_buy = 0, time_of_trade_sell = 0, time_of_trade_open_buy = 0, time_of_trade_open_sell = 0, zigzag_low_time, bb_bar_sell_sig = 0;
int prev_bar_of_candle_buy = 0, prev_bar_of_candle_sell = 0, prev_trade_signal_bar = 0, prev_trade_signal_bar2 = 0, bb_bar_buy_sig = 0, bb_bar_buy_sig_check = 0;
bool trade_check = false, trade_check2 = false, bb_buy_std, bb_buy_rsi, bb_sell_std, bb_sell_rsi;
int regular_buy_div_time = 0, regular_sell_div_time = 0, bb_bar_buy = 0, bb_bar_sell = 0, prev_bb_bar_buy_sig = 0, shift_of_candle_inside = 0, bb_bar_sell_sig_check = 0;
datetime regular_buy_div_time_ht = 0, regular_sell_div_time_ht = 0;
datetime time_of_trade_open_buy_time = 0, time_of_trade_open_sell_time = 0;
double high, low, zigzagup_, zigzagdown_;
datetime history_start = TimeCurrent();

void OnDeinit(const int reason)
{

     IndicatorRelease(bb_handle);
     IndicatorRelease(bb_handle2);
     IndicatorRelease(mafasthandle);
     IndicatorRelease(maslowhandle);
     IndicatorRelease(rsi_handle);
     IndicatorRelease(std_handle);
     IndicatorRelease(hkn_ashi_handle);
     
}
  

void divergence(double& zigzagup, double& zigzagdown, double& zigzagup2, double& zigzagdown2, datetime& zigzaguptime,
                datetime& zigzagdowntime, datetime& zigzaguptime2, datetime& zigzagdowntime2, int depth, int deviation, 
                int backstep, ENUM_TIMEFRAMES tf, int& variable_for_div_shift_buy, int& variable_for_div_shift_sell, bool& sell_div_htf_check, bool& buy_div_htf_check, datetime& variable_for_div_shift_buy_htf, datetime& variable_for_div_shift_sell_htf)
{
   int zz_handle = iCustom(_Symbol,tf,"\\Indicators\\Examples\\ZigZag.ex5",depth,deviation,backstep);
  double zz_high[], zz_low[], zz_col[];
  CopyBuffer(zz_handle, 1, 0, 301, zz_high);
  CopyBuffer(zz_handle, 2, 0, 301, zz_low);
  CopyBuffer(zz_handle, 0, 0, 301, zz_col);
  ArraySetAsSeries(zz_high, true);
  ArraySetAsSeries(zz_low, true);
  ArraySetAsSeries(zz_col, true);
   
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= 0 ; i<100; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(_Symbol,tf,i);
         zigzagdown = downarrow;
         two_down = i;
         //Print("found zz down time = ",zigzagdowntime," on shift ",i,"");
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

   for(int i= 0 ; i<100; i++)
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
     
     
   if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime)
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
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",tf == lower_timeframe ? clrRed:clrMaroon);
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",tf == lower_timeframe ? clrRed:clrMaroon);
            
            if (tf == lower_timeframe)
            variable_for_div_shift_sell = Bars(_Symbol, tf) - iBarShift(_Symbol, tf, zigzagdowntime);
            
            if (tf == timeframe)
            {
            variable_for_div_shift_sell_htf = zigzagdowntime;
            sell_div_htf_check = true;
            }
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2)
     {       
         int to = iBarShift(_Symbol,tf,zigzagdowntime2);
         int from = iBarShift(_Symbol,tf,zigzaguptime2);
         double first_rsi = minRSIValue(from, to, tf);
         datetime first_rsi_time = minRSITime(from, to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzagdowntime);
         int from2 = iBarShift(_Symbol,tf,zigzaguptime);
         double second_rsi = minRSIValue(from2, to2, tf);
         datetime second_rsi_time = maxRSITime(from2, to2, tf);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",tf == lower_timeframe ? clrLawnGreen:clrGreen);
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",tf == lower_timeframe ? clrLawnGreen:clrGreen);
            
            if (tf == lower_timeframe)
            {
            variable_for_div_shift_buy = Bars(_Symbol, tf) - iBarShift(_Symbol, tf, zigzaguptime);
            }
            
            if (tf == timeframe)
            {
            variable_for_div_shift_buy_htf = zigzaguptime;
            buy_div_htf_check = true;
            }
         }
     }
}



void OnTick()
{

  mafasthandle = iMA(_Symbol, lower_timeframe, fastmaperiod, 0, mamethod, appliedprice);
  maslowhandle = iMA(_Symbol, lower_timeframe, slowmaperiod, 0, mamethod, appliedprice);
  rsi_handle = iRSI(_Symbol, lower_timeframe, rsi_period, rsi_appliedprice);
  //std_handle = iStdDev(_Symbol, lower_timeframe, std_period, 0, std_method, std_appliedprice);
  std_handle = 0;
  bb_handle = iBands(_Symbol, lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
  bb_handle2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
  
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  MqlDateTime date;
  MqlDateTime date2;
  TimeCurrent(date);
  
  CopyBuffer(mafasthandle, 0, 1, range_for_candle_outside, mafast);
  CopyBuffer(maslowhandle, 0, 1, range_for_candle_outside, maslow);
  CopyBuffer(bb_handle, 1, 1, range_for_candle_outside, bb_upper);
  CopyBuffer(bb_handle, 2, 1, range_for_candle_outside, bb_lower);
  CopyBuffer(bb_handle2, 1, 1, range_for_candle_outside, bb_upper2);
  CopyBuffer(bb_handle2, 2, 1, range_for_candle_outside, bb_lower2);
  SymbolInfoTick(_Symbol, latest_price);
  
  ArraySetAsSeries(mafast, true);
  ArraySetAsSeries(maslow, true);
  ArraySetAsSeries(bb_lower, true);
  ArraySetAsSeries(bb_upper, true);
  ArraySetAsSeries(bb_lower2, true);
  ArraySetAsSeries(bb_upper2, true);
  
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
   
   bool found_reg_buy_div = false;
   bool found_reg_sell_div = false;

if (use_zz == true)   
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}

if (use_zz2 == true)
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}
          
if (use_zz3 == true) 
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}

    
  int zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
  double zz_high2[], zz_low2[], zz_col2[];
  CopyBuffer(zz_handle2, 1, 0, 301, zz_high2);
  CopyBuffer(zz_handle2, 2, 0, 301, zz_low2);
  CopyBuffer(zz_handle2, 0, 0, 301, zz_col2);
  ArraySetAsSeries(zz_high2, true);
  ArraySetAsSeries(zz_low2, true);
  ArraySetAsSeries(zz_col2, true);
   
   zigzagup=0;
   zigzagup2=0;
   zigzagdown=0;
   zigzagdown2=0;
   secondzigzagup=0;
   secondzigzagup2=0;
   secondzigzagdown=0;
   secondzigzagdown2=0;
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= 0 ; i<100; i++)
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
   for(int i= two_down+1 ; i<200; i++)
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

   for(int i= 0 ; i<100; i++)
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
   for(int i=  two_up+1 ; i<200; i++)
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
     
     
  //the below zz are for zz bsed sl only   
  double zigzagdown22, zigzagup22;
   for(int i= zz4_shift ; i<100; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdown22 = downarrow;
         //Print("found zz down time = ",zigzagdowntime," on shift ",i,"");
         break;
        }
     }
   
   for(int i= zz4_shift ; i<100; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {
         zigzagup22 = uparrow;
         break;

        }
     }

  //+------------------------------------------------------------------+
  //|   martingale                                                     |
  //+------------------------------------------------------------------+
  
  if (PositionSelect(_Symbol) && martingale_exit1 == true)
  {
  ulong ticket = PositionGetTicket(return_pos(_Symbol));
  if (  (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= high) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL  )
  {
    setorder(POSITION_TYPE_BUY, _Symbol);
    //Print("sent buy order  high = ",high," ask = ",SymbolInfoDouble(_Symbol,SYMBOL_ASK),"");
  }
  
  if (  (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= low) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
  {
    setorder(POSITION_TYPE_SELL, _Symbol);
    //Print("sent buy order  low = ",low,"  bid = ",SymbolInfoDouble(_Symbol,SYMBOL_BID),"");
  }
  }
  
  

  if (trade_check == true && PositionSelect(_Symbol) == false)
  {
  trade_check = false;
  long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL))
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
     
  time_of_trade_buy = Bars(_Symbol, lower_timeframe);
  trade_close_shift = Bars(_Symbol, lower_timeframe);
  } 
  
  if (trade_check2 == true && PositionSelect(_Symbol) == false)
  {
  trade_check2 = false;
  long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY))
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
     
  time_of_trade_sell = Bars(_Symbol, lower_timeframe);
  trade_close_shift = Bars(_Symbol, lower_timeframe);
  }
  
  
  if (iLow(_Symbol, lower_timeframe, 1) < bb_lower[0] && iLow(_Symbol, lower_timeframe, 1) < bb_lower2[0])
  bb_bar_buy_sig_check = Bars(_Symbol, lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iLow(_Symbol, lower_timeframe, i) < bb_lower[i-1] && iLow(_Symbol, lower_timeframe, i) < bb_lower2[i-1]) &&  ((mafast[i-1] > maslow[i-1] && allow_ma_in_entry) || (!allow_ma_in_entry)))
    {
    bb_bar_buy_sig = Bars(_Symbol, lower_timeframe) - i;
    break;
    }
  }
  
  if ( prev_bb_bar_buy_sig != bb_bar_buy_sig && (iClose(_Symbol, lower_timeframe, 1) > bb_lower[0] || iClose(_Symbol, lower_timeframe, 1) > bb_lower2[0]) )
  {
   prev_bb_bar_buy_sig = bb_bar_buy_sig;
   shift_of_candle_inside = Bars(_Symbol, lower_timeframe) - 1;
  }
  
  if ( prev_bb_bar_buy_sig1 != bb_bar_buy_sig && ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2) || 
        (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(_Symbol, lower_timeframe, zigzaguptime) > 0)) &&  Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzaguptime2) >= bb_bar_buy_sig )
  {
   prev_bb_bar_buy_sig1 = bb_bar_buy_sig;
   zigzag_low_time1 = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzaguptime2);
  }
  
  
  double llow = iLow(_Symbol, lower_timeframe, Bars(_Symbol, lower_timeframe) - shift_of_candle_inside);
  int llow_shift = 0;
  for(int i = Bars(_Symbol, lower_timeframe) - shift_of_candle_inside; i <= lookback + (Bars(_Symbol, lower_timeframe) - shift_of_candle_inside); i++)  //for finding sl low
  {
  
    if ( iLow(_Symbol, lower_timeframe, i) <= llow )
    {
    llow = iLow(_Symbol, lower_timeframe, i);
    llow_shift = Bars(_Symbol, lower_timeframe) - i; 
    }
    
  }
  
  if (  ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2) || 
        (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(_Symbol, lower_timeframe, zigzaguptime) > 0))  ) 
  {
  zigzag_low = zigzagup2;
  zigzag_low_time = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzaguptime2);
  }
  
  bool llow_checked = false;
  if (zigzag_low < llow )
  {
   bb_bar_buy =  zigzag_low_time;  
   llow = iLow(_Symbol, lower_timeframe, Bars(_Symbol, lower_timeframe) - bb_bar_buy);
   llow_checked = true;
  }
  
  if (zigzag_low >= llow && llow_checked == false)
  {
  bb_bar_buy = llow_shift; 
  llow = llow;
  }
  
  //Print("cond1 = ",bb_bar_buy_sig == bb_bar_buy_sig_check,"  cond2 = ",bb_bar_buy_sig >= trade_close_shift,"  cond3 = ",bb_bar_buy_sig <= zigzag_low_time,"  cond4 = ",zigzag_low_time == zigzag_low_time1,"  cond5 = ",bb_bar_buy >= trade_close_shift,"  bb bar buy = ",Bars(_Symbol,lower_timeframe)-bb_bar_buy,"  tradecloseshift = ",Bars(_Symbol,lower_timeframe)-trade_close_shift,"");
  
  bool cond_2 = ((bb_bar_buy_sig == bb_bar_buy_sig_check && bb_bar_buy_sig >= trade_close_shift && bb_bar_buy_sig <= zigzag_low_time && zigzag_low_time == zigzag_low_time1 && time_of_trade_open_buy != Bars(_Symbol, lower_timeframe) && bb_bar_buy >= trade_close_shift && single_trade == true && allow_zigzag_entry == true && PositionSelect(_Symbol) == false) ||
                 (bb_bar_buy_sig == bb_bar_buy_sig_check && bb_bar_buy_sig >= trade_close_shift && bb_bar_buy_sig <= zigzag_low_time &&  zigzag_low_time == zigzag_low_time1 && time_of_trade_open_buy != Bars(_Symbol, lower_timeframe) && multi_trade == true && prev_trade_signal_bar != bb_bar_buy && allow_zigzag_entry == true));
  
  
  CopyBuffer(std_handle, 0, Bars(_Symbol, lower_timeframe) - bb_bar_buy, std_bar_range, std_val);
  CopyBuffer(rsi_handle, 0, Bars(_Symbol, lower_timeframe) - bb_bar_buy, 1, rsi_val);
  ArraySetAsSeries(std_val, true);
  ArraySetAsSeries(rsi_val, true);
  
  int std_lowest_index = ArrayMinimum(std_val, 0);
  double std_lowest = std_val[std_lowest_index];
  
  bb_buy_rsi = rsi_val[0] <= rsi_os_lev; 
  bb_buy_std = std_val[0] <= std_lowest;
  

  bool rsi_cond_buy = false;
  if ( allow_rsi_in_entry == true && bb_buy_rsi == true )
  rsi_cond_buy = true;
  
  bool std_cond_buy = false;
  if ( allow_std_dev_in_entry == true && bb_buy_std == true ) //nili aunty said that we dont need standard deviation in the strategy
  std_cond_buy = true;
  
  bool div_cond_buy = false;
  if ( allow_div_in_entry == true && bb_bar_buy == regular_buy_div_time && bb_bar_buy != 0 )
  div_cond_buy = true;
  
  bool any_one_option_cond_buy = false;
  if ( allow_any_one_entry == true && (bb_buy_rsi == true || bb_bar_buy == regular_buy_div_time) && bb_bar_buy != 0 )
  any_one_option_cond_buy = true;
  

  if ( (cond_2) && ((cond_2 == true && allow_any_one_entry == false && allow_div_in_entry == false && allow_rsi_in_entry == false)                 ||
                    (div_cond_buy == true)   ||
                    (rsi_cond_buy == true)   ||
                    (any_one_option_cond_buy == true)) )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price - (_Point*(fixed_sl_pips*10)), _Digits) : swing_hi_lo == true ? llow : zz_swing == true ? zigzagup22 : zz_first == true ? zigzagup2 : first_trade_exit == true ? 0:0; //change sl to lowest val
         double pips = (mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
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
         Print("last trade made profit ", istradeprofit(_Symbol));
         } 
   
         mrequest.sl = slt == 0 ? 0 : slt - (_Point*10); 
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price + (_Point*(fixed_tp_pips*10)), _Digits) : 0;
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
           pos_tf = lower_timeframe;
           time_of_trade_open_buy = Bars(_Symbol, lower_timeframe);
           time_of_trade_open_buy_time = iTime(_Symbol, lower_timeframe, 0);
           prev_trade_signal_bar = bb_bar_buy;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print(" for buy | bar out of band = ",Bars(_Symbol, lower_timeframe) - bb_bar_buy_sig,"  zigzag first low bar = ",Bars(_Symbol, lower_timeframe) - zigzag_low_time," div time = ",regular_buy_div_time,"  bb bar buy = ",bb_bar_buy,"");
           bb_buy_std = false;
           bb_buy_rsi = false;
           trade_check = true;
           
           if(martingale_exit2 == true)
           counter++;
           
           high = mrequest.price;
           low = zigzagup;
           if (  (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= low) )
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

  
  
  
  if (iHigh(_Symbol, lower_timeframe, 1) > bb_upper[0] && iHigh(_Symbol, lower_timeframe, 1) > bb_upper2[0])
  bb_bar_sell_sig_check = Bars(_Symbol, lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iHigh(_Symbol, lower_timeframe, i) > bb_upper[i-1] && iHigh(_Symbol, lower_timeframe, i) > bb_upper2[i-1]) &&  ((mafast[i-1] < maslow[i-1] && allow_ma_in_entry) || (!allow_ma_in_entry)))
    {
    bb_bar_sell_sig = Bars(_Symbol, lower_timeframe) - i;
    break;
    }
  }
  
  if ( prev_bb_bar_sell_sig != bb_bar_sell_sig && (iClose(_Symbol, lower_timeframe, 1) < bb_upper[0] || iClose(_Symbol, lower_timeframe, 1) < bb_upper2[0]) )
  {
   prev_bb_bar_sell_sig = bb_bar_sell_sig;
   shift_of_candle_inside2 = Bars(_Symbol, lower_timeframe) - 1;
  }
  
  if ( prev_bb_bar_sell_sig1 != bb_bar_sell_sig && ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2) || 
        (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 1) < zigzagup && zigzagdown < zigzagdown2 && iBarShift(_Symbol, lower_timeframe, zigzagdowntime) > 0)) &&  Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime2) >= bb_bar_sell_sig )
  {
   prev_bb_bar_sell_sig1 = bb_bar_sell_sig;
   zigzag_high_time1 = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
  }
  
  
  double hhigh = iHigh(_Symbol, lower_timeframe, Bars(_Symbol, lower_timeframe) - shift_of_candle_inside2);
  int hhigh_shift = 0;
  for(int i = Bars(_Symbol, lower_timeframe) - shift_of_candle_inside2; i <= lookback + (Bars(_Symbol, lower_timeframe) - shift_of_candle_inside2); i++)
  {
    
    if ( iHigh(_Symbol, lower_timeframe, i) >= hhigh )
    {
    hhigh = iHigh(_Symbol, lower_timeframe, i);
    hhigh_shift = Bars(_Symbol, lower_timeframe) - i;
    }
  }
  
  
   if (  ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2) || 
        (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 1) < zigzagup && zigzagdown < zigzagdown2 && iBarShift(_Symbol, lower_timeframe, zigzagdowntime) > 0))  ) 
  {
  zigzag_high = zigzagdown2;
  zigzag_high_time = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
  }
  
  bool hhigh_checked = false;
  if (zigzag_high > hhigh )
  {
   bb_bar_sell =  zigzag_high_time;  
   hhigh = iHigh(_Symbol, lower_timeframe, Bars(_Symbol, lower_timeframe) - bb_bar_sell);
   hhigh_checked = true;
  }
  
  if (zigzag_high <= hhigh && hhigh_checked == false)
  {
  bb_bar_sell = hhigh_shift; 
  hhigh = hhigh;
  }
  
  bool cond_22 = ((bb_bar_sell_sig_check == bb_bar_sell_sig && bb_bar_sell_sig >= trade_close_shift && bb_bar_sell_sig <= zigzag_high_time && zigzag_high_time1 == zigzag_high_time && time_of_trade_open_sell != Bars(_Symbol, lower_timeframe) && bb_bar_sell >= trade_close_shift && single_trade == true && allow_zigzag_entry == true && PositionSelect(_Symbol) == false ) ||
                  (bb_bar_sell_sig_check == bb_bar_sell_sig && bb_bar_sell_sig >= trade_close_shift && bb_bar_sell_sig <= zigzag_high_time && zigzag_high_time1 == zigzag_high_time && time_of_trade_open_sell != Bars(_Symbol, lower_timeframe) && multi_trade == true && allow_zigzag_entry == true && prev_trade_signal_bar2 != bb_bar_sell));
  
  
  CopyBuffer(std_handle, 0, Bars(_Symbol, lower_timeframe) - bb_bar_sell, std_bar_range, std_val2);
  CopyBuffer(rsi_handle, 0, Bars(_Symbol, lower_timeframe) - bb_bar_sell, 1, rsi_val2);
  ArraySetAsSeries(std_val2, true);
  ArraySetAsSeries(rsi_val2, true);
  
  std_lowest_index = ArrayMinimum(std_val2, 0);
  std_lowest = std_val2[std_lowest_index];
  
  bb_sell_rsi = rsi_val2[0] >= rsi_ob_lev; //subtract bb_bar buy from bars on the chart to get correect index for rsi_val & std val
  bb_sell_std = std_val2[0] <= std_lowest;
  
  
  bool rsi_cond_sell = false;
  if ( allow_rsi_in_entry == true && bb_sell_rsi == true )
  rsi_cond_sell = true;
  
  bool std_cond_sell = false;
  if ( allow_std_dev_in_entry == true && bb_sell_std == true )
  std_cond_sell = true;
  
  bool div_cond_sell = false;
  if ( allow_div_in_entry == true && bb_bar_sell == regular_sell_div_time && bb_bar_sell != 0 )
  div_cond_sell = true;
  
  bool any_one_option_cond_sell = false;
  if ( allow_any_one_entry == true && (bb_sell_rsi == true || bb_bar_sell == regular_sell_div_time) && bb_bar_sell != 0 )
  any_one_option_cond_sell = true;
  
  
  if ( (cond_22 == true) && ((cond_22 == true && allow_any_one_entry == false && allow_div_in_entry == false && allow_rsi_in_entry == false)                 ||
                             (div_cond_sell == true)           ||
                             (rsi_cond_sell == true)           ||
                             (any_one_option_cond_sell == true)) )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
      
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price + (_Point*(fixed_sl_pips*10)), _Digits) : swing_hi_lo == true ? hhigh : zz_swing == true ? zigzagdown22 : zz_first == true ? zigzagdown2 : first_trade_exit == true ? 0 : 0;  //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > mrequest.price ? slt - mrequest.price:mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
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
         
         mrequest.sl = slt == 0 ? 0:slt + (_Point*10);
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price - (_Point*(fixed_tp_pips*10)), _Digits) : 0; 
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
           pos_tf = lower_timeframe;
           time_of_trade_open_sell = Bars(_Symbol, lower_timeframe);
           time_of_trade_open_sell_time = iTime(_Symbol, lower_timeframe, 0);
           prev_trade_signal_bar2 = bb_bar_sell;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print(" for sell |  first zz high = ",Bars(_Symbol, lower_timeframe) - zigzag_high_time,"  candle outside band = ",Bars(_Symbol, lower_timeframe) - bb_bar_sell_sig,"  candle inside band = ",Bars(_Symbol, lower_timeframe) - shift_of_candle_inside2,"  sl = ",hhigh,"  div = ",Bars(_Symbol, lower_timeframe)-regular_buy_div_time,"");
           bb_sell_rsi = false; 
           bb_sell_std = false;
           trade_check2 = true;
           
           if(martingale_exit2 == true)
           counter++;
           
           high = zigzagdown;
           low = mrequest.price;
           if ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= high) )
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
     
     datetime time_of_trade_open = time_of_trade_open_buy_time > time_of_trade_open_sell_time ? time_of_trade_open_buy_time:time_of_trade_open_sell_time;
     if(latest_close > time_of_trade_open) //check if most recent close time is greater than time_of_open_trade2, if so then close all open orders
     {
       close_all(_Symbol);
     }
       
   }
   
 //closing when total profit is 0 only when the breakeven exit is allowed
   if(breakeven_exit == true && count >= trades_for_breakeven)  
   { 
     if(profit_total(_Symbol) >= 0)
     {
       close_all(_Symbol);
     }
   }

  
  zigzagup=0;
   zigzagup2=0;
   zigzagdown=0;
   zigzagdown2=0;
   secondzigzagup=0;
   secondzigzagup2=0;
   secondzigzagdown=0;
   secondzigzagdown2=0;
if (use_zz == true)   
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}

if (use_zz2 == true)
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}
          
if (use_zz3 == true) 
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, timeframe, 
           regular_buy_div_time, regular_sell_div_time, found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht, regular_sell_div_time_ht);
}
  
  if ( PositionSelect(_Symbol) ) 
  {
    
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    if ( type == POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == _Symbol )
    {
      if ( iClose(_Symbol, pos_tf, 0) >= (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) && allow_breakeven_sl == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) + ((breakeven_pips*10) * _Point); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         bool res = OrderSend(mrequest, mresult);
      }
      
      if ( allow_div_based_close == true && found_reg_sell_div == true && regular_sell_div_time_ht >= time_of_trade_open_buy_time )
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
      
      int han1 = iBands(_Symbol, lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
      int han2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
      double han1_buff[], han2_buff[];
      CopyBuffer(han1, 2, 0, 1, han1_buff);
      CopyBuffer(han2, 2, 0, 1, han2_buff);
      ArraySetAsSeries(han1_buff, true);
      ArraySetAsSeries(han2_buff, true);
      
      if ( allow_outer_band_cross_close == true && (iLow(_Symbol, lower_timeframe, 0) < han1_buff[0] || iLow(_Symbol, lower_timeframe, 0) < han2_buff[0]) && PositionGetDouble(POSITION_PROFIT) > 0 )
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
      if ( iClose(_Symbol, pos_tf, 0) <= (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) && allow_breakeven_sl == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) - ((breakeven_pips*10) * _Point); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         bool res = OrderSend(mrequest, mresult);
      } 
      
      if ( allow_div_based_close == true && found_reg_buy_div == true && regular_buy_div_time_ht >= time_of_trade_open_sell_time )
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
      
      int han1 = iBands(_Symbol, lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
      int han2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
      double han1_buff[], han2_buff[];
      CopyBuffer(han1, 1, 0, 1, han1_buff);
      CopyBuffer(han2, 1, 0, 1, han2_buff);
      ArraySetAsSeries(han1_buff, true);
      ArraySetAsSeries(han2_buff, true);
      
       if ( allow_outer_band_cross_close == true && (iHigh(_Symbol, lower_timeframe, 0) > han1_buff[0] || iHigh(_Symbol, lower_timeframe, 0) > han2_buff[0]) && PositionGetDouble(POSITION_PROFIT) > 0 )
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
    
  }
  

void setorder(ENUM_POSITION_TYPE order_type, string symb) //sets pending orders with doubles lotsize and correct order type and entry price
{

  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);
  double pos_sl2, pos_tp2, entry_price;
  int count = 0;
  
     
      ulong  position_ticket=PositionGetTicket(return_pos(symb));
      long digits = SymbolInfoInteger(symb, SYMBOL_DIGITS);
      entry_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_BID), digits):NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_ASK), digits);                            
    
         pos_sl2 = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? PositionGetDouble(POSITION_TP):PositionGetDouble(POSITION_TP);   
         pos_tp2 = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? PositionGetDouble(POSITION_SL):PositionGetDouble(POSITION_SL);   
         
         request.action = TRADE_ACTION_DEAL;                                
         request.price = entry_price;
         request.sl = pos_sl2;
         request.tp = pos_tp2;
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
           Print("The sell order request could not be completed -error :",GetLastError());
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
           high = PositionGetDouble(POSITION_PRICE_OPEN);
           else
           low = PositionGetDouble(POSITION_PRICE_OPEN);
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
