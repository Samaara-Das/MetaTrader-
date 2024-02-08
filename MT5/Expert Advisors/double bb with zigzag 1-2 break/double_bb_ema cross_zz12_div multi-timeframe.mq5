#property copyright 
#property link      "https://www.mql5.com"
#property version   "10.00"
//EA LOGIC description : 200 and 50 ema buy/sell cross (trend bias), price outside the both bb and then closing inside one of the bbs, 
//div/rsi to be there (optional) and entry when heikin ashi buy/sell candle or zigzag 1-2 break pattern. closing with div / RR/ fixed/ bb. 
//stop loss as per look back bars (to find the highest/lowest). 
//rsi with zigzag divergence logic used in the ea for divergence.

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

input string ___ = " "; //   " "

//parameters for bb
input string bb_param = " ";  //Fill Bollinger Bands Parameters Below
input int bbmaperiod = 20;    //First Bollinger Bands MA Period
input double bb_dev = 2.0;    //Deviation for First Bollinger Band
input ENUM_APPLIED_PRICE bbappliedprice = PRICE_CLOSE; //Applied First Bollinger Band Price
input int bbmaperiod2 = 20;    //Second Bollinger Bands MA Period
input double bb_dev2 = 2.0;    //Deviation for Second Bollinger Band
input ENUM_APPLIED_PRICE bbappliedprice2 = PRICE_CLOSE; //Applied Second Bollinger Band Price

input string ____ = " "; //  " "

//parameters for rsi
input string rsi_param = " ";  //Fill RSI Parameters Below
input ENUM_APPLIED_PRICE rsi_appliedprice = PRICE_CLOSE; //Applied Price for RSI
input int rsi_period = 14; //Period for RSi
input double rsi_ob_lev = 70; //RSI Overbought Level
input double rsi_os_lev = 30; //RSI Oversold Level

input string _ = " "; //  " "

//parameters for stdDev
input string stddev_param = " "; //Fill StdDev Parameters Below
input int std_period = 20; //StdDev Period
input ENUM_APPLIED_PRICE std_appliedprice = PRICE_CLOSE; //StdDev Applied price
input ENUM_MA_METHOD std_method = MODE_SMA; //StdDev Ma Method

input string hh = " "; // " "

input string zz_param = " "; //Fill ZigZag Parameters
input int zz_arrow_depth = 12; //Depth
input int zz_arrow_deviation = 5; //Deviation
input int zz_arrow_backStep = 3; //Backstep

input string _____ = " "; //  " "

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool allow_risk_reward_based_close = false; //Allow Risk-Reward Based Closing
input bool allow_div_based_close = false; //Allow Divergence Based Closing
input bool allow_outer_band_cross_close = false; //Allow Outer Band Cross Based Closing

input bool allow_div_in_entry = false; //Allow Divergence Based Entry
bool allow_std_dev_in_entry = true; //Allow StdDev Based Entry
input bool allow_rsi_in_entry = false; //Allow Rsi Oversold/UnderBought Based Entry
input bool allow_any_one_entry = false; //Allow Any one of the above 2 options
input bool allow_hkn_ashi_entry = false; //Allow Heiken Ashi Based entry
input bool allow_zigzag_entry = false; //Allow Zigzag 1-2 break Based entry

input int lookback = 4;  //LookBack Bars For Stoploss Candle
input int range_for_candle_outside = 4; //Lookback for Finding Candle outside of band 
int std_bar_range = 10; //Bar Range for StdDev
input bool fixed_tp = false; // Fixed Takeprofit
input double fixed_tp_pips = 10; //Fixed Takeprofit pips
input double risk_reward_tp = 2; //Risk to Reward Ratio
input double breakeven_ratio = 1; //Break Even Ratio
input double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price
input bool single_trade = true; //Single Trade
input bool multi_trade = false; //Multi Trade
 bool candle_out_of_both = true; //Candle Outside of Both Bollinger Bands
input double Risk = 0.01; // Free margin fraction you want to risk for the trade
input ENUM_TIMEFRAMES timeframe = PERIOD_M1; //Timeframe for Divergence Close Condition 

//handles & indicator buffer arrays
int bb_handle, bb_handle2, maslowhandle, mafasthandle, div_handle; 
int rsi_handle, std_handle, hkn_ashi_handle;
double maslow[], mafast[], bb_upper[], bb_lower[], rsi_val[], rsi_val2[];
double bb_lower2[], bb_upper2[], std_val[], std_val2[], hkn_ashi_val[];
double hkn_ashi_close[], hkn_ashi_low[], hkn_ashi_high[];

int prev_bb_bar_sell_sig = 0, shift_of_candle_inside2 = 0, zigzag_high_time;
double pos_tp, pos_sl, bb_buy_low, bb_sell_high, zigzag_low = 0.0, zigzag_high = 0.0;
int time_of_trade_buy = 0, time_of_trade_sell = 0, time_of_trade_open_buy = 0, time_of_trade_open_sell = 0, zigzag_low_time, bb_bar_sell_sig = 0;
int prev_bar_of_candle_buy = 0, prev_bar_of_candle_sell = 0, prev_trade_signal_bar = 0, prev_trade_signal_bar2 = 0, bb_bar_buy_sig = 0, bb_bar_buy_sig_check = 0;
bool trade_check = false, trade_check2 = false, bb_buy_std, bb_buy_rsi, bb_sell_std, bb_sell_rsi;
int regular_buy_div_time = 0, regular_sell_div_time = 0, bb_bar_buy = 0, bb_bar_sell = 0, prev_bb_bar_buy_sig = 0, shift_of_candle_inside = 0, bb_bar_sell_sig_check = 0;
datetime regular_buy_div_time_ht = 0, regular_sell_div_time_ht = 0;
datetime time_of_trade_open_buy_time = 0, time_of_trade_open_sell_time = 0;

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
  
  
void OnTick()
{

  for(int j = 1; j <= 3; j++)
  {
   ENUM_TIMEFRAMES lower_timeframe = j == 1 ? PERIOD_M15: j == 2 ? PERIOD_H1: j == 3 ? PERIOD_H4: PERIOD_CURRENT; //Timeframe for Trade Entry
   ENUM_TIMEFRAMES pos_tf = lower_timeframe;
  
  mafasthandle = iMA(_Symbol, lower_timeframe, fastmaperiod, 0, mamethod, appliedprice);
  maslowhandle = iMA(_Symbol, lower_timeframe, slowmaperiod, 0, mamethod, appliedprice);
  rsi_handle = iRSI(_Symbol, lower_timeframe, rsi_period, rsi_appliedprice);
  //std_handle = iStdDev(_Symbol, lower_timeframe, std_period, 0, std_method, std_appliedprice);
  std_handle = 0;
  hkn_ashi_handle = iCustom(_Symbol, lower_timeframe, "Heiken_Ashi");
  bb_handle = iBands(_Symbol, lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
  bb_handle2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
  
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  
  CopyBuffer(mafasthandle, 0, 1, range_for_candle_outside, mafast);
  CopyBuffer(maslowhandle, 0, 1, range_for_candle_outside, maslow);
  CopyBuffer(bb_handle, 1, 1, range_for_candle_outside, bb_upper);
  CopyBuffer(bb_handle, 2, 1, range_for_candle_outside, bb_lower);
  CopyBuffer(bb_handle2, 1, 1, range_for_candle_outside, bb_upper2);
  CopyBuffer(bb_handle2, 2, 1, range_for_candle_outside, bb_lower2);
  CopyBuffer(hkn_ashi_handle, 4, 1, 1, hkn_ashi_val);  //0 for blue candles and 1 for red candles
  CopyBuffer(hkn_ashi_handle, 3, 1, 1, hkn_ashi_close); //close price for heiken ashi candles
  CopyBuffer(hkn_ashi_handle, 2, 2, 1, hkn_ashi_low); //low price for heiken ashi candles
  CopyBuffer(hkn_ashi_handle, 1, 2, 1, hkn_ashi_high); //low price for heiken ashi candles
  SymbolInfoTick(_Symbol, latest_price);
  
  ArraySetAsSeries(mafast, true);
  ArraySetAsSeries(maslow, true);
  ArraySetAsSeries(bb_lower, true);
  ArraySetAsSeries(bb_upper, true);
  ArraySetAsSeries(bb_lower2, true);
  ArraySetAsSeries(bb_upper2, true);
  ArraySetAsSeries(hkn_ashi_val, true);
  ArraySetAsSeries(hkn_ashi_close, true);
  ArraySetAsSeries(hkn_ashi_low, true);
  ArraySetAsSeries(hkn_ashi_high, true);

  int zz_handle = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth,zz_arrow_deviation,zz_arrow_backStep);
  double zz_high[], zz_low[], zz_col[];
  CopyBuffer(zz_handle, 1, 0, 301, zz_high);
  CopyBuffer(zz_handle, 2, 0, 301, zz_low);
  CopyBuffer(zz_handle, 0, 0, 301, zz_col);
  ArraySetAsSeries(zz_high, true);
  ArraySetAsSeries(zz_low, true);
  ArraySetAsSeries(zz_col, true);
  
  int zz_handle2 = iCustom(_Symbol,timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth,zz_arrow_deviation,zz_arrow_backStep);
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
   
  double zigzagup21=0;
   double zigzagup221=0;
   double zigzagdown21=0;
   double zigzagdown221=0;
   double secondzigzagup21=0;
   double secondzigzagup221=0;
   double secondzigzagdown21=0;
   double secondzigzagdown221=0;
   datetime zigzagdowntime21=NULL,zigzagdowntime221=NULL;
   datetime zigzaguptime21 = NULL,zigzaguptime221 = NULL;
   datetime secondzigzagdowntime21=NULL,secondzigzagdowntime221=NULL;
   datetime secondzigzaguptime21 = NULL,secondzigzaguptime221 = NULL;
   int two_up21=0,two_down21=0,second_two_up21=0,second_two_down21=0;
   
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

//--------------------------
 
 //higher timeframe divergence
   for(int i= 1 ; i<100; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime21 = iTime(_Symbol,timeframe,i);
         zigzagdown21 = downarrow;
         two_down21 = i;
         break;
        }
     }
   for(int i= two_down21+1 ; i<200; i++)
     {
      double downarrow=zz_high2[i]; //up val
      double zero=zz_col2[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime221 = iTime(_Symbol,timeframe,i);
         zigzagdown221 = downarrow;
         break;
        }
     }


   for(int i= 1 ; i<100; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {

         zigzaguptime21 = iTime(_Symbol,timeframe,i);
         zigzagup21 = uparrow;
         two_up21 = i;
         break;

        }
     }
   for(int i=  two_up21+1 ; i<200; i++)
     {
      double uparrow=zz_low2[i]; //down val
      double zero=zz_col2[i];
      if(uparrow>0 && zero > 0)
        {
         zigzaguptime221 = iTime(_Symbol,timeframe,i);
         zigzagup221 = uparrow;
         break;
        }
     }


   if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime)
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
            regular_sell_div_time = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime);
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2)
     {       
         int to = iBarShift(_Symbol,lower_timeframe,zigzagdowntime2);
         int from = iBarShift(_Symbol,lower_timeframe,zigzaguptime2);
         double first_rsi = minRSIValue(from, to, lower_timeframe);
         datetime first_rsi_time = minRSITime(from, to, lower_timeframe);
         int to2 = iBarShift(_Symbol,lower_timeframe,zigzagdowntime);
         int from2 = iBarShift(_Symbol,lower_timeframe,zigzaguptime);
         double second_rsi = minRSIValue(from2, to2, lower_timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, lower_timeframe);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",clrLawnGreen);
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",clrLawnGreen);
            regular_buy_div_time = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzaguptime);
         }
     }
  
  
   //higher timeframe diveregnce
    bool found_reg_sell_div = false;
    if(zigzagdown21 > zigzagdown221 && zigzagup21 > zigzagup221 && zigzaguptime21 < zigzagdowntime21)
     {
         int to = iBarShift(_Symbol,timeframe,zigzaguptime221);
         int from = iBarShift(_Symbol,timeframe,zigzagdowntime221);
         double first_rsi = maxRSIValue(from, to, timeframe);
         datetime first_rsi_time = maxRSITime(from, to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzaguptime21);
         int from2 = iBarShift(_Symbol,timeframe,zigzagdowntime21);
         double second_rsi = maxRSIValue(from2, to2, timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzaguptime221,zigzagup221,zigzagdowntime221,zigzagdown221,"firstReversal1",clrMaroon);
            TrendCreate(zigzaguptime21,zigzagup21,zigzagdowntime21,zigzagdown21,"firstReversal2",clrMaroon);
            found_reg_sell_div = true;
            regular_sell_div_time_ht = zigzagdowntime21;
         }
     }
     
   bool found_reg_buy_div = false;
   if(zigzaguptime21 > zigzagdowntime21 && zigzagup21 < zigzagup221 && zigzagdown21 < zigzagdown221)
     {       
         int to = iBarShift(_Symbol,timeframe,zigzagdowntime221);
         int from = iBarShift(_Symbol,timeframe,zigzaguptime221);
         double first_rsi = minRSIValue(from, to, timeframe);
         datetime first_rsi_time = minRSITime(from, to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzagdowntime21);
         int from2 = iBarShift(_Symbol,timeframe,zigzaguptime21);
         double second_rsi = minRSIValue(from2, to2, timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime221,zigzagdown221,zigzaguptime221,zigzagup221,"firstReversal1",clrGreen);
            TrendCreate(zigzagdowntime21,zigzagdown21,zigzaguptime21,zigzagup21,"firstReversal2",clrGreen);
            found_reg_buy_div = true;
            regular_buy_div_time_ht = zigzaguptime21;
         }
     }
     
     

  if (trade_check == true && PositionSelect(_Symbol) == false)
  {
  trade_check = false;
  time_of_trade_buy = Bars(_Symbol, lower_timeframe) - 1;
  } 
  
  
  
  if (iLow(_Symbol, lower_timeframe, 1) < bb_lower[0] && iLow(_Symbol, lower_timeframe, 1) < bb_lower2[0])
  bb_bar_buy_sig_check = Bars(_Symbol, lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iLow(_Symbol, lower_timeframe, i) < bb_lower[i-1] && iLow(_Symbol, lower_timeframe, i) < bb_lower2[i-1]) &&  (mafast[i-1] > maslow[i-1]))
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
  
  
  
  
  double llow = iLow(_Symbol, lower_timeframe, Bars(_Symbol, lower_timeframe) - shift_of_candle_inside);
  int llow_shift = 0;
  for(int i = Bars(_Symbol, lower_timeframe) - shift_of_candle_inside; i <= lookback + (Bars(_Symbol, lower_timeframe) - shift_of_candle_inside); i++)  //for finding sl low
  {
  
    if ( iLow(_Symbol, lower_timeframe, i) <= llow )
    {
    llow = iLow(_Symbol, lower_timeframe, i);
    llow_shift = Bars(_Symbol, lower_timeframe) - i; //remove this line from here
    }
    
  }
  
  
  if (  ((zigzagdowntime > zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime < zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2) || 
        (zigzagdowntime < zigzaguptime && iHigh(_Symbol, lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(_Symbol, lower_timeframe, zigzaguptime) > 0))  ) 
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
  

  bool cond_2 = ((bb_bar_buy_sig == bb_bar_buy_sig_check && bb_bar_buy_sig >= time_of_trade_buy && bb_bar_buy_sig <= zigzag_low_time && time_of_trade_open_buy != Bars(_Symbol, lower_timeframe) && bb_bar_buy >= time_of_trade_buy && single_trade == true && allow_zigzag_entry == true && PositionSelect(_Symbol) == false) ||
                 (bb_bar_buy_sig == bb_bar_buy_sig_check && bb_bar_buy_sig >= time_of_trade_buy && bb_bar_buy_sig <= zigzag_low_time && time_of_trade_open_buy != Bars(_Symbol, lower_timeframe) && multi_trade == true && prev_trade_signal_bar != bb_bar_buy && allow_zigzag_entry == true));
 
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
  if ( allow_std_dev_in_entry == true && bb_buy_std == true )
  std_cond_buy = true;
  
  bool div_cond_buy = false;
  if ( allow_div_in_entry == true && bb_bar_buy == regular_buy_div_time )
  div_cond_buy = true;
  
  bool any_one_option_cond_buy = false;
  if ( allow_any_one_entry == true && (bb_buy_rsi == true || bb_bar_buy == regular_buy_div_time) )
  any_one_option_cond_buy = true;
  

  if ( (cond_2) && ((cond_2)                 ||
                    (div_cond_buy == true)   ||
                    (rsi_cond_buy == true)   ||
                    (any_one_option_cond_buy == true)) )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
         
         double slt = llow; //change sl to lowest val
         double pips = (mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
   
         mrequest.sl = slt - (_Point*10); 
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price + (_Point*(fixed_tp_pips*10)), _Digits) : 0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           pos_tf = lower_timeframe;
           time_of_trade_open_buy = Bars(_Symbol, lower_timeframe);
           time_of_trade_open_buy_time = iTime(_Symbol, lower_timeframe, 0);
           prev_trade_signal_bar = bb_bar_buy;
           Print(" for buy | bar out of band = ",Bars(_Symbol, lower_timeframe) - bb_bar_buy_sig,"  zigzag first low bar = ",Bars(_Symbol, lower_timeframe) - zigzag_low_time,"  sl = ",llow,"");
           bb_buy_std = false;
           bb_buy_rsi = false;
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }

  if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
  trade_check = true;
  
  
  
  
  
  if (trade_check2 == true && PositionSelect(_Symbol) == false)
  {
  trade_check2 = false;
  time_of_trade_sell = Bars(_Symbol, lower_timeframe) - 1;
  }
  
  if (iHigh(_Symbol, lower_timeframe, 1) > bb_upper[0] && iHigh(_Symbol, lower_timeframe, 1) > bb_upper2[0])
  bb_bar_sell_sig_check = Bars(_Symbol, lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iHigh(_Symbol, lower_timeframe, i) > bb_upper[i-1] && iHigh(_Symbol, lower_timeframe, i) > bb_upper2[i-1]) &&  (mafast[i-1] < maslow[i-1]))
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
  
  
   if (  ((zigzagdowntime < zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime > zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2) || 
        (zigzagdowntime > zigzaguptime && iLow(_Symbol, lower_timeframe, 1) < zigzagup && zigzagdown < zigzagdown2 && iBarShift(_Symbol, lower_timeframe, zigzagdowntime) > 0))  ) 
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
  
 
  bool cond_22 = ((bb_bar_sell_sig_check == bb_bar_sell_sig && bb_bar_sell_sig >= time_of_trade_sell && bb_bar_sell_sig <= zigzag_high_time && time_of_trade_open_sell != Bars(_Symbol, lower_timeframe) && bb_bar_sell >= time_of_trade_sell && single_trade == true && allow_zigzag_entry == true && PositionSelect(_Symbol) == false ) ||
                  (bb_bar_sell_sig_check == bb_bar_sell_sig && bb_bar_sell_sig >= time_of_trade_sell && bb_bar_sell_sig <= zigzag_high_time && time_of_trade_open_sell != Bars(_Symbol, lower_timeframe) && multi_trade == true && allow_zigzag_entry == true && prev_trade_signal_bar2 != bb_bar_sell));
  
  
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
  if ( allow_div_in_entry == true && bb_bar_sell == regular_sell_div_time )
  div_cond_sell = true;
  
  bool any_one_option_cond_sell = false;
  if ( allow_any_one_entry == true && (bb_sell_rsi == true || bb_bar_sell == regular_sell_div_time) )
  any_one_option_cond_sell = true;
  
  
  if ( (cond_22 == true) && ((cond_22 == true)                 ||
                             (div_cond_sell == true)           ||
                             (rsi_cond_sell == true)           ||
                             (any_one_option_cond_sell == true)) )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
         
         double slt = hhigh;  //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt - mrequest.price)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*_Point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         mrequest.sl = slt + (_Point*10);
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price - (_Point*(fixed_tp_pips*10)), _Digits) : 0; 
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           pos_tf = lower_timeframe;
           time_of_trade_open_sell = Bars(_Symbol, lower_timeframe);
           time_of_trade_open_sell_time = iTime(_Symbol, lower_timeframe, 0);
           prev_trade_signal_bar2 = bb_bar_sell;
           Print(" for sell |  first zz high = ",Bars(_Symbol, lower_timeframe) - zigzag_high_time,"  candle outside band = ",Bars(_Symbol, lower_timeframe) - bb_bar_sell_sig,"  candle inside band = ",Bars(_Symbol, lower_timeframe) - shift_of_candle_inside2,"  sl = ",hhigh," ");
           bb_sell_rsi = false; 
           bb_sell_std = false;
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
  }
 
  if (PositionSelect(_Symbol) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
  trade_check2 = true;
  
  
  
  if ( PositionSelect(_Symbol) ) 
  {
    
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    if ( type == POSITION_TYPE_BUY )
    {
      if ( iClose(_Symbol, pos_tf, 0) >= (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) + ((breakeven_pips*10) * _Point); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         OrderSend(mrequest, mresult);
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
         OrderSend(mrequest, mresult);
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
         OrderSend(mrequest, mresult);
      }
    }
    
    
    if ( type == POSITION_TYPE_SELL )
    {
      if ( iClose(_Symbol, pos_tf, 0) <= (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) - ((breakeven_pips*10) * _Point); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         OrderSend(mrequest, mresult);
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
         OrderSend(mrequest, mresult);
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
         OrderSend(mrequest, mresult);
       
       }
      }
    }
    
    }
    
    
    
   }
    
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
