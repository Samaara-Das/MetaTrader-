#property copyright "sammy"
#property link      "https://www.mql5.com"
#property version   "13.00"
//EA LOGIC description : 200 and 50 ema buy/sell cross (trend bias), price outside the both bb and then closing inside one of the bbs, 
//div/rsi to be there (optional) and entry when heikin ashi buy/sell candle or zigzag 1-2 break pattern. closing with div / RR/ fixed/ bb. 
//stop loss as per look back bars (to find the highest/lowest). 
//rsi with zigzag divergence logic used in the ea for divergence & multipile divergences are used
//fixed pip sl added nad heiken ashi removed with martingale option
//added a different kind of martingale which increases lotsize if last trade was a loss & resets to initial lotsize if last trade was a profit.

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

//parameters for ema
//input string latest8Heiken;
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

input string hh = " "; // _

input string zz_param = " "; //Fill ZigZag Parameters Below
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

input string _____ = " "; // _

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input string entry = " "; //Fill Entry Conditions
input bool allow_div_in_entry = false; //Allow Divergence Based Entry
bool allow_std_dev_in_entry = true; //Allow StdDev Based Entry
input bool allow_rsi_in_entry = false; //Allow Rsi Oversold/UnderBought Based Entry
input bool allow_any_one_entry = false; //Allow Any one of the above 2 options
input bool allow_zigzag_entry = false; //Allow Zigzag 1-2 break Based entry
input bool single_trade = true; //Single Trade
input bool multi_trade = false; //Multi Trade

input string ff = " "; // _
input string close = " "; //Fill Closing Conditions
input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
//input bool breakeven_exit = false; //Breakeven Exit
//input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute
input bool allow_risk_reward_based_close = false; //Allow Risk-Reward Based Closing
input bool allow_div_based_close = false; //Allow Divergence Based Closing
input bool allow_outer_band_cross_close = false; //Allow Outer Band Cross Based Closing
input bool first_trade_exit = false; //First Trade Exit
input bool allow_breakeven_sl = false; //Allow sl to be Breakeven Price
input bool fixed_tp = false; // Fixed Takeprofit
input bool fixed_sl = false; // Fixed StopLoss
input bool swing_hi_lo = true; // LookBack bar based stoploss
input bool zz_swing = false; // ZigZag Swing high/low Based StopLoss

input string tg = " "; // _

input string rr_entry_settings = " "; //Fill Sl TP & Entry Settings
input int lookback = 8;  //LookBack For Finding Highest/Lowest bar before Candle outside band
input int range_for_candle_outside = 6; //Lookback for Finding Candle outside of band 
int std_bar_range = 10; //Bar Range for StdDev
input double fixed_tp_pips = 10; //Fixed Takeprofit pips
input double fixed_sl_pips = 50; //Fixed Stoploss pips
input double risk_reward_tp = 2; //Risk to Reward Ratio
input double mtgl_risk_reward_sl = 3; //mtgl sl
input double mtgl_risk_reward_tp = 2; //mtgl tp
input double breakeven_ratio = 1; //Break Even Ratio
input double breakeven_pips = 2; //Pips to Be Added/Subtracted from Breakeven price

input string hyt = " "; // _

bool candle_out_of_both = true; //Candle Outside of Both Bollinger Bands
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // Free margin percentage you want to risk for the trade
input double inital_lots = 0.01; //Initial Lots
input ENUM_TIMEFRAMES timeframe = PERIOD_M5; //Timeframe for Divergence Close Condition 
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int start = 4; //Start Time
input int end = 23; //End Time
input string user_symbols = "GBPUSD,GBPJPY";

//handles & indicator buffer arrays
int bb_handle, bb_handle2, maslowhandle, mafasthandle, div_handle; 
int rsi_handle, std_handle, hkn_ashi_handle;
double maslow[], mafast[], bb_upper[], bb_lower[], rsi_val[], rsi_val2[];
double bb_lower2[], bb_upper2[], std_val[], std_val2[], hkn_ashi_val[];
double hkn_ashi_close[], hkn_ashi_low[], hkn_ashi_high[];
string symbols[];

ENUM_TIMEFRAMES pos_tf = lower_timeframe;

//bb
int prev_bb_bar_sell_sig[], shift_of_candle_inside2[], prev_bb_bar_sell_sig1[], prev_bb_bar_buy_sig1[];
int bb_buy_low[], bb_sell_high[], bb_bar_sell_sig[], bb_bar_buy[], bb_bar_sell[], prev_bb_bar_buy_sig[], shift_of_candle_inside[], bb_bar_sell_sig_check[];
int prev_bar_of_candle_buy[], prev_bar_of_candle_sell[], prev_trade_signal_bar[], prev_trade_signal_bar2[], bb_bar_buy_sig[], bb_bar_buy_sig_check[];

//zz
int zigzag_high_time1[], zigzag_low_time1[], zigzag_high_time[], zigzag_low_time[];
double zigzag_low[], zigzag_high[];

//trade
datetime time_of_trade_open_buy_time[], time_of_trade_open_sell_time[];
int time_of_trade_buy[], time_of_trade_sell[], time_of_trade_open_buy[], time_of_trade_open_sell[], trade_close_shift[], counter[];
bool trade_check[], trade_check2[], bb_buy_std[], bb_buy_rsi[], bb_sell_std[], bb_sell_rsi[];
double high[], low[];

//div
datetime regular_buy_div_time_ht[], regular_sell_div_time_ht[];
int regular_buy_div_time[], regular_sell_div_time[];


datetime history_start = TimeCurrent();

string delim = ",";
int size;


int OnInit(void)
{

  ushort sdelim = StringGetCharacter(delim, 0);   
  StringSplit(user_symbols, sdelim, symbols);
  size = ArraySize(symbols);
  Print(size);
 
 //bb 
 ArrayResize(bb_bar_buy, size); ArrayResize(bb_bar_sell, size); ArrayResize(prev_bb_bar_buy_sig, size); ArrayResize(shift_of_candle_inside, size); ArrayResize(bb_bar_sell_sig_check, size);
 ArrayResize(prev_bb_bar_sell_sig, size); ArrayResize(shift_of_candle_inside2, size); ArrayResize(prev_bb_bar_sell_sig1, size); ArrayResize(prev_bb_bar_buy_sig1, size); ArrayResize(bb_bar_sell_sig, size);
 ArrayResize(bb_buy_low, size); ArrayResize(bb_sell_high, size);
 ArrayResize(prev_bar_of_candle_buy, size); ArrayResize(prev_bar_of_candle_sell, size); ArrayResize(prev_trade_signal_bar, size); ArrayResize(prev_trade_signal_bar2, size); ArrayResize(bb_bar_buy_sig, size); ArrayResize(bb_bar_buy_sig_check, size);
 
 //zz
 ArrayResize(zigzag_high_time1, size); ArrayResize(zigzag_low_time1, size); ArrayResize(zigzag_high_time, size); ArrayResize(zigzag_low_time, size);
 ArrayResize(zigzag_low, size); ArrayResize(zigzag_high, size);
 
 //trade
 ArrayResize(time_of_trade_buy, size); ArrayResize(time_of_trade_sell, size); ArrayResize(time_of_trade_open_buy, size); ArrayResize(time_of_trade_open_sell, size);
 ArrayResize(trade_check, size); ArrayResize(trade_check2, size); ArrayResize(bb_buy_std, size); ArrayResize(bb_buy_rsi, size); ArrayResize(bb_sell_std, size); ArrayResize(bb_sell_rsi, size);
 ArrayResize(time_of_trade_open_buy_time, size); ArrayResize(time_of_trade_open_sell_time, size);ArrayResize(trade_close_shift, size);ArrayResize(counter, size);
 ArrayResize(low, size); ArrayResize(high, size);
 
 //div
 ArrayResize(regular_buy_div_time, size); ArrayResize(regular_sell_div_time, size);
 ArrayResize(regular_buy_div_time_ht, size); ArrayResize(regular_sell_div_time_ht, size);


   return(INIT_SUCCEEDED);
}

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
                int backstep, ENUM_TIMEFRAMES tf, int& variable_for_div_shift_buy, int& variable_for_div_shift_sell, bool& sell_div_htf_check, bool& buy_div_htf_check, datetime& variable_for_div_shift_buy_htf, datetime& variable_for_div_shift_sell_htf, string symb)
{
   int zz_handle = iCustom(symb,tf,"\\Indicators\\Examples\\ZigZag.ex5",depth,deviation,backstep);
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
         zigzagdowntime = iTime(symb,tf,i);
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
         zigzagdowntime2 = iTime(symb,tf,i);
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

         zigzaguptime = iTime(symb,tf,i);
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
         zigzaguptime2 = iTime(symb,tf,i);
         zigzagup2 = uparrow;
         break;
        }
     }
     
     
   if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime)
     {
         int to = iBarShift(symb,tf,zigzaguptime2);
         int from = iBarShift(symb,tf,zigzagdowntime2);
         double first_rsi = maxRSIValue(from, to, tf, symb);
         datetime first_rsi_time = maxRSITime(from, to, tf, symb);
         int to2 = iBarShift(symb,tf,zigzaguptime);
         int from2 = iBarShift(symb,tf,zigzagdowntime);
         double second_rsi = maxRSIValue(from2, to2, tf, symb);
         datetime second_rsi_time = maxRSITime(from2, to2, tf, symb);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",tf == lower_timeframe ? clrRed:clrMaroon);
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",tf == lower_timeframe ? clrRed:clrMaroon);
  
            if (tf == lower_timeframe)
            {
            variable_for_div_shift_sell = Bars(symb, tf) - iBarShift(symb, tf, zigzagdowntime);
            }
            
            if (tf == timeframe)
            {
            variable_for_div_shift_sell_htf = zigzagdowntime;
            sell_div_htf_check = true;
            }
         }
     }
   
   if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2)
     {       
         int to = iBarShift(symb,tf,zigzagdowntime2);
         int from = iBarShift(symb,tf,zigzaguptime2);
         double first_rsi = minRSIValue(from, to, tf, symb);
         datetime first_rsi_time = minRSITime(from, to, tf, symb);
         int to2 = iBarShift(symb,tf,zigzagdowntime);
         int from2 = iBarShift(symb,tf,zigzaguptime);
         double second_rsi = minRSIValue(from2, to2, tf, symb);
         datetime second_rsi_time = maxRSITime(from2, to2, tf, symb);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",tf == lower_timeframe ? clrLawnGreen:clrGreen);
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",tf == lower_timeframe ? clrLawnGreen:clrGreen);
            
            if (tf == lower_timeframe)
            {
            variable_for_div_shift_buy = Bars(symb, tf) - iBarShift(symb, tf, zigzaguptime);
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

  for(int j =0; j < size; j++)
  {
  mafasthandle = iMA(symbols[j], lower_timeframe, fastmaperiod, 0, mamethod, appliedprice);
  maslowhandle = iMA(symbols[j], lower_timeframe, slowmaperiod, 0, mamethod, appliedprice);
  rsi_handle = iRSI(symbols[j], lower_timeframe, rsi_period, rsi_appliedprice);
  //std_handle = iStdDev(symbols[j], lower_timeframe, std_period, 0, std_method, std_appliedprice);
  std_handle = 0;
  bb_handle = iBands(symbols[j], lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
  bb_handle2 = iBands(symbols[j], lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
  
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  MqlDateTime date2;
  MqlDateTime date;
  TimeCurrent(date);
  
  CopyBuffer(mafasthandle, 0, 1, range_for_candle_outside, mafast);
  CopyBuffer(maslowhandle, 0, 1, range_for_candle_outside, maslow);
  CopyBuffer(bb_handle, 1, 1, range_for_candle_outside, bb_upper);
  CopyBuffer(bb_handle, 2, 1, range_for_candle_outside, bb_lower);
  CopyBuffer(bb_handle2, 1, 1, range_for_candle_outside, bb_upper2);
  CopyBuffer(bb_handle2, 2, 1, range_for_candle_outside, bb_lower2);
  SymbolInfoTick(symbols[j], latest_price);
  
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
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}

if (use_zz2 == true)
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, 
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}
          
if (use_zz3 == true) 
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, 
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}

    
  int zz_handle2 = iCustom(symbols[j],lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
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
         zigzagdowntime = iTime(symbols[j],lower_timeframe,i);
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
         zigzagdowntime2 = iTime(symbols[j],lower_timeframe,i);
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

         zigzaguptime = iTime(symbols[j],lower_timeframe,i);
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
         zigzaguptime2 = iTime(symbols[j],lower_timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     } 
     

  //+------------------------------------------------------------------+
  //|   martingale                                                     |
  //+------------------------------------------------------------------+
  
  if (PositionSelect(symbols[j]) && martingale_exit1 == true)
  {
  ulong ticket = PositionGetTicket(return_pos(symbols[j]));
  if (  (SymbolInfoDouble(symbols[j],SYMBOL_ASK) >= high[j]) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL  )
  {
    setorder(POSITION_TYPE_BUY, symbols[j], j);
    //Print("sent buy order  high = ",high," ask = ",SymbolInfoDouble(symbols[j],SYMBOL_ASK),"");
  }
  
  if (  (SymbolInfoDouble(symbols[j],SYMBOL_BID) <= low[j]) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
  {
    setorder(POSITION_TYPE_SELL, symbols[j], j);
    //Print("sent buy order  low = ",low,"  bid = ",SymbolInfoDouble(symbols[j],SYMBOL_BID),"");
  }
  }
  
  

  if (trade_check[j] == true && PositionSelect(symbols[j]) == false)
  {
  trade_check[j] = false;
  long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_SELL)) //this doesnt work... the last deal may not be the last deal for the current symbol we are checking
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
     
  time_of_trade_buy[j] = Bars(symbols[j], lower_timeframe);
  trade_close_shift[j] = Bars(symbols[j], lower_timeframe);
  } 
  
  
  
  if (iLow(symbols[j], lower_timeframe, 1) < bb_lower[0] && iLow(symbols[j], lower_timeframe, 1) < bb_lower2[0])
  bb_bar_buy_sig_check[j] = Bars(symbols[j], lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iLow(symbols[j], lower_timeframe, i) < bb_lower[i-1] && iLow(symbols[j], lower_timeframe, i) < bb_lower2[i-1]) &&  (mafast[i-1] > maslow[i-1]))
    {
    bb_bar_buy_sig[j] = Bars(symbols[j], lower_timeframe) - i;
    break;
    }
  }
  
  if ( prev_bb_bar_buy_sig[j] != bb_bar_buy_sig[j] && (iClose(symbols[j], lower_timeframe, 1) > bb_lower[0] || iClose(symbols[j], lower_timeframe, 1) > bb_lower2[0]) )
  {
   prev_bb_bar_buy_sig[j] = bb_bar_buy_sig[j];
   shift_of_candle_inside[j] = Bars(symbols[j], lower_timeframe) - 1;
  }
  
  if ( prev_bb_bar_buy_sig1[j] != bb_bar_buy_sig[j] && ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(symbols[j], lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2) || 
        (zigzagdowntime <= zigzaguptime && iHigh(symbols[j], lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(symbols[j], lower_timeframe, zigzaguptime) > 0)) &&  Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzaguptime2) >= bb_bar_buy_sig[j] )
  {
   prev_bb_bar_buy_sig1[j] = bb_bar_buy_sig[j];
   zigzag_low_time1[j] = Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzaguptime2);
  }
  
  
  double llow = iLow(symbols[j], lower_timeframe, Bars(symbols[j], lower_timeframe) - shift_of_candle_inside[j]);
  int llow_shift = 0;
  for(int i = Bars(symbols[j], lower_timeframe) - shift_of_candle_inside[j]; i <= lookback + (Bars(symbols[j], lower_timeframe) - shift_of_candle_inside[j]); i++)  //for finding sl low
  {
  
    if ( iLow(symbols[j], lower_timeframe, i) <= llow )
    {
    llow = iLow(symbols[j], lower_timeframe, i);
    llow_shift = Bars(symbols[j], lower_timeframe) - i; 
    }
    
  }
  
  if (  (zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(symbols[j], lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2) || 
        (zigzagdowntime <= zigzaguptime && iHigh(symbols[j], lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(symbols[j], lower_timeframe, zigzaguptime) > 0)  ) 
  {
  zigzag_low[j] = zigzagup2;
  zigzag_low_time[j] = Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzaguptime2);
  }
  
  bool llow_checked = false;
  if (zigzag_low[j] < llow )
  {
   bb_bar_buy[j] =  zigzag_low_time[j];  
   llow = iLow(symbols[j], lower_timeframe, Bars(symbols[j], lower_timeframe) - bb_bar_buy[j]);
   llow_checked = true;
  }
  
  if (zigzag_low[j] >= llow && llow_checked == false)
  {
  bb_bar_buy[j] = llow_shift; 
  llow = llow;
  }
  
  bool cond_2 = ((bb_bar_buy_sig[j] == bb_bar_buy_sig_check[j] && bb_bar_buy_sig[j] >= time_of_trade_buy[j] && bb_bar_buy_sig[j] <= zigzag_low_time[j] && zigzag_low_time[j] == zigzag_low_time1[j] && time_of_trade_open_buy[j] != Bars(symbols[j], lower_timeframe) && bb_bar_buy[j] >= time_of_trade_buy[j] && single_trade == true && allow_zigzag_entry == true && PositionSelect(symbols[j]) == false) ||
                 (bb_bar_buy_sig[j] == bb_bar_buy_sig_check[j] && bb_bar_buy_sig[j] >= time_of_trade_buy[j] && bb_bar_buy_sig[j] <= zigzag_low_time[j] &&  zigzag_low_time[j] == zigzag_low_time1[j] && time_of_trade_open_buy[j] != Bars(symbols[j], lower_timeframe) && multi_trade == true && prev_trade_signal_bar[j] != bb_bar_buy[j] && allow_zigzag_entry == true));
  
  
  CopyBuffer(std_handle, 0, Bars(symbols[j], lower_timeframe) - bb_bar_buy[j], std_bar_range, std_val);
  CopyBuffer(rsi_handle, 0, Bars(symbols[j], lower_timeframe) - bb_bar_buy[j], 1, rsi_val);
  ArraySetAsSeries(std_val, true);
  ArraySetAsSeries(rsi_val, true);
  
  int std_lowest_index = ArrayMinimum(std_val, 0);
  double std_lowest = std_val[std_lowest_index];
  
  bb_buy_rsi[j] = rsi_val[0] <= rsi_os_lev; 
  bb_sell_std[j] = std_val[0] <= std_lowest;
  

  bool rsi_cond_buy = false;
  if ( allow_rsi_in_entry == true && bb_buy_rsi[j] == true )
  rsi_cond_buy = true;
  
  bool std_cond_buy = false;
  if ( allow_std_dev_in_entry == true && bb_sell_std[j] == true ) //nili aunty said that we dont need standard deviation in the strategy
  std_cond_buy = true;
  
  bool div_cond_buy = false;
  if ( allow_div_in_entry == true && bb_bar_buy[j] == regular_buy_div_time[j] && bb_bar_buy[j] != 0 )
  div_cond_buy = true;
  
  bool any_one_option_cond_buy = false;
  if ( allow_any_one_entry == true && (bb_buy_rsi[j] == true || bb_bar_buy[j] == regular_buy_div_time[j]) && bb_bar_buy[j] != 0 )
  any_one_option_cond_buy = true;
  

  if ( (cond_2) && ((cond_2 == true && allow_any_one_entry == false && allow_div_in_entry == false && allow_rsi_in_entry == false)                 ||
                    (div_cond_buy == true)   ||
                    (rsi_cond_buy == true)   ||
                    (any_one_option_cond_buy == true)) )
  {
         long digits = SymbolInfoInteger(symbols[j], SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbols[j],SYMBOL_POINT); 
  
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.ask,digits);
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price - (point*(fixed_sl_pips*10)), digits) : swing_hi_lo == true ? llow : zz_swing == true ? zigzagup : first_trade_exit == true ? 0:0; //change sl to lowest val
         double pips = (mrequest.price - slt)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
   
         if(martingale_exit2 == false) 
         Lots = use_inital_lots == true ? inital_lots:Lots; 
         
         if(counter[j] >= 1 && istradeprofit(symbols[j]) < 0 && martingale_exit2 == true)
         {
         Lots = lotsize(symbols[j]);
         Print("last trade made loss ",istradeprofit(symbols[j]),"  ",istradeprofit(symbols[j]) < 0," ",counter[j] >= 1,"");
         }
         
         if((counter[j] == 0 || (counter[j] >= 1 && istradeprofit(symbols[j]) >= 0)) && martingale_exit2 == true)
         {
         Lots  = use_inital_lots == true ? inital_lots:Lots; 
         Print("last trade made profit ",istradeprofit(symbols[j]),"  ",istradeprofit(symbols[j]) >= 0," ",counter[j] >= 1,"");
         } 
   
         mrequest.sl = slt == 0 ? 0 : slt - (point*10); 
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), digits) : fixed_tp == true ? NormalizeDouble(mrequest.price + (point*(fixed_tp_pips*10)), digits) : 0;
         mrequest.symbol = symbols[j];                                         
         mrequest.volume = Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         int min_index1 = MathMin(zigzag_low_time[j], bb_bar_buy_sig[j]);
         int min_index2 = MathMin(min_index1, bb_bar_buy[j]);
         int min_index3 = Bars(symbols[j], lower_timeframe) - min_index2;
         datetime time = iTime(symbols[j], lower_timeframe, min_index3);
         TimeToStruct(time, date2);
         
         if(date.hour >= start && date.hour < end && date2.hour >= start && date2.hour < end)
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           pos_tf = lower_timeframe;
           time_of_trade_open_buy[j] = Bars(symbols[j], lower_timeframe);
           time_of_trade_open_buy_time[j] = iTime(symbols[j], lower_timeframe, 0);
           prev_trade_signal_bar[j] = bb_bar_buy[j];
           Print(" for buy | bar out of band = ",Bars(symbols[j], lower_timeframe) - bb_bar_buy_sig[j],"  zigzag first low bar = ",Bars(symbols[j], lower_timeframe) - zigzag_low_time[j]," div time = ",regular_buy_div_time[j],"  bb bar buy = ",bb_bar_buy[j],"");
           bb_sell_std[j] = false;
           bb_buy_rsi[j] = false;
           trade_check[j] = true;
           counter[j]++;
           
           high[j] = mrequest.price;
           low[j] = zigzagup;
           if (  (SymbolInfoDouble(symbols[j],SYMBOL_BID) <= low[j]) )
            {
              if(martingale_exit1 == true)
              setorder(POSITION_TYPE_SELL, symbols[j], j);
            }
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }
  
  
  
  
  
  if (trade_check2[j] == true && PositionSelect(symbols[j]) == false)
  {
  trade_check2[j] = false;
  long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY))
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
     
  time_of_trade_sell[j] = Bars(symbols[j], lower_timeframe);
  trade_close_shift[j] = Bars(symbols[j], lower_timeframe);
  }
  
  if (iHigh(symbols[j], lower_timeframe, 1) > bb_upper[0] && iHigh(symbols[j], lower_timeframe, 1) > bb_upper2[0])
  bb_bar_sell_sig_check[j] = Bars(symbols[j], lower_timeframe) - 1;
  
  for(int i = 1; i <= range_for_candle_outside; i++)
  {
    if ((iHigh(symbols[j], lower_timeframe, i) > bb_upper[i-1] && iHigh(symbols[j], lower_timeframe, i) > bb_upper2[i-1]) &&  (mafast[i-1] < maslow[i-1]))
    {
    bb_bar_sell_sig[j] = Bars(symbols[j], lower_timeframe) - i;
    break;
    }
  }
  
  if ( prev_bb_bar_sell_sig[j] != bb_bar_sell_sig[j] && (iClose(symbols[j], lower_timeframe, 1) < bb_upper[0] || iClose(symbols[j], lower_timeframe, 1) < bb_upper2[0]) )
  {
   prev_bb_bar_sell_sig[j] = bb_bar_sell_sig[j];
   shift_of_candle_inside2[j] = Bars(symbols[j], lower_timeframe) - 1;
  }
  
  if ( prev_bb_bar_sell_sig1[j] != bb_bar_sell_sig[j] && ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(symbols[j], lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2) || 
        (zigzagdowntime >= zigzaguptime && iLow(symbols[j], lower_timeframe, 1) < zigzagup && zigzagdown < zigzagdown2 && iBarShift(symbols[j], lower_timeframe, zigzagdowntime) > 0)) &&  Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzagdowntime2) >= bb_bar_sell_sig[j] )
  {
   prev_bb_bar_sell_sig1[j] = bb_bar_sell_sig[j];
   zigzag_high_time1[j] = Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzagdowntime2);
  }
  
  
  double hhigh = iHigh(symbols[j], lower_timeframe, Bars(symbols[j], lower_timeframe) - shift_of_candle_inside2[j]);
  int hhigh_shift = 0;
  for(int i = Bars(symbols[j], lower_timeframe) - shift_of_candle_inside2[j]; i <= lookback + (Bars(symbols[j], lower_timeframe) - shift_of_candle_inside2[j]); i++)
  {
    
    if ( iHigh(symbols[j], lower_timeframe, i) >= hhigh )
    {
    hhigh = iHigh(symbols[j], lower_timeframe, i);
    hhigh_shift = Bars(symbols[j], lower_timeframe) - i;
    }
  }
  
  
   if (  ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(symbols[j], lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2) || 
        (zigzagdowntime >= zigzaguptime && iLow(symbols[j], lower_timeframe, 1) < zigzagup && zigzagdown < zigzagdown2 && iBarShift(symbols[j], lower_timeframe, zigzagdowntime) > 0))  ) 
  {
  zigzag_high[j] = zigzagdown2;
  zigzag_high_time[j] = Bars(symbols[j], lower_timeframe) - iBarShift(symbols[j], lower_timeframe, zigzagdowntime2);
  }
  
  bool hhigh_checked = false;
  if (zigzag_high[j] > hhigh )
  {
   bb_bar_sell[j] =  zigzag_high_time[j];  
   hhigh = iHigh(symbols[j], lower_timeframe, Bars(symbols[j], lower_timeframe) - bb_bar_sell[j]);
   hhigh_checked = true;
  }
  
  if (zigzag_high[j] <= hhigh && hhigh_checked == false)
  {
  bb_bar_sell[j] = hhigh_shift; 
  hhigh = hhigh;
  }
  
  bool cond_22 = ((bb_bar_sell_sig_check[j] == bb_bar_sell_sig[j] && bb_bar_sell_sig[j] >= time_of_trade_sell[j] && bb_bar_sell_sig[j] <= zigzag_high_time[j] && zigzag_high_time1[j] == zigzag_high_time[j] && time_of_trade_open_sell[j] != Bars(symbols[j], lower_timeframe) && bb_bar_sell[j] >= time_of_trade_sell[j] && single_trade == true && allow_zigzag_entry == true && PositionSelect(symbols[j]) == false ) ||
                  (bb_bar_sell_sig_check[j] == bb_bar_sell_sig[j] && bb_bar_sell_sig[j] >= time_of_trade_sell[j] && bb_bar_sell_sig[j] <= zigzag_high_time[j] && zigzag_high_time1[j] == zigzag_high_time[j] && time_of_trade_open_sell[j] != Bars(symbols[j], lower_timeframe) && multi_trade == true && allow_zigzag_entry == true && prev_trade_signal_bar2[j] != bb_bar_sell[j]));
  
  
  CopyBuffer(std_handle, 0, Bars(symbols[j], lower_timeframe) - bb_bar_sell[j], std_bar_range, std_val2);
  CopyBuffer(rsi_handle, 0, Bars(symbols[j], lower_timeframe) - bb_bar_sell[j], 1, rsi_val2);
  ArraySetAsSeries(std_val2, true);
  ArraySetAsSeries(rsi_val2, true);
  
  std_lowest_index = ArrayMinimum(std_val2, 0);
  std_lowest = std_val2[std_lowest_index];
  
  bb_sell_rsi[j] = rsi_val2[0] >= rsi_ob_lev; //subtract bb_bar buy from bars on the chart to get correect index for rsi_val & std val
  bb_sell_std[j] = std_val2[0] <= std_lowest;
  
  
  bool rsi_cond_sell = false;
  if ( allow_rsi_in_entry == true && bb_sell_rsi[j] == true )
  rsi_cond_sell = true;
  
  bool std_cond_sell = false;
  if ( allow_std_dev_in_entry == true && bb_sell_std[j] == true )
  std_cond_sell = true;
  
  bool div_cond_sell = false;
  if ( allow_div_in_entry == true && bb_bar_sell[j] == regular_sell_div_time[j] && bb_bar_sell[j] != 0 )
  div_cond_sell = true;
  
  bool any_one_option_cond_sell = false;
  if ( allow_any_one_entry == true && (bb_sell_rsi[j] == true || bb_bar_sell[j] == regular_sell_div_time[j]) && bb_bar_sell[j] != 0 )
  any_one_option_cond_sell = true;
  
  
  if ( (cond_22 == true) && ((cond_22 == true && allow_any_one_entry == false && allow_div_in_entry == false && allow_rsi_in_entry == false)                 ||
                             (div_cond_sell == true)           ||
                             (rsi_cond_sell == true)           ||
                             (any_one_option_cond_sell == true)) )
  {
         long digits = SymbolInfoInteger(symbols[j], SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbols[j],SYMBOL_POINT); 
  
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,digits);
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price + (point*(fixed_sl_pips*10)), digits) : swing_hi_lo == true ? hhigh : zz_swing == true ? zigzagdown : first_trade_exit == true ? 0 : 0;  //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > mrequest.price ? slt - mrequest.price:mrequest.price - slt)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         if(martingale_exit2 == false) 
         Lots = use_inital_lots == true ? inital_lots:Lots; 
         
         if(counter[j] >= 1 && istradeprofit(symbols[j]) < 0 && martingale_exit2 == true)
         {
         Lots = lotsize(symbols[j]);
         Print("last trade made loss ",istradeprofit(symbols[j]),"  ",istradeprofit(symbols[j]) < 0," ",counter[j] >= 1,"");
         }
         
         if((counter[j] == 0 || (counter[j] >= 1 && istradeprofit(symbols[j]) >= 0)) && martingale_exit2 == true)
         {
         Lots  = use_inital_lots == true ? inital_lots:Lots; 
         Print("last trade made profit ",istradeprofit(symbols[j]),"  ",istradeprofit(symbols[j]) >= 0," ",counter[j] >= 1,"");
         } 
         
         mrequest.sl = slt == 0 ? 0:slt + (point*10);
         mrequest.tp = allow_risk_reward_based_close ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), digits) : fixed_tp == true ? NormalizeDouble(mrequest.price - (point*(fixed_tp_pips*10)), digits) : 0; 
         mrequest.symbol = symbols[j];                                         
         mrequest.volume = Lots;                                              
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         int min_index1 = MathMin(zigzag_high_time[j], bb_bar_sell_sig[j]);
         int min_index2 = MathMin(min_index1, bb_bar_sell[j]);
         int min_index3 = Bars(symbols[j], lower_timeframe) - min_index2;
         datetime time = iTime(symbols[j], lower_timeframe, min_index3);
         TimeToStruct(time, date2);
         
         if(date.hour >= start && date.hour < end && date2.hour >= start && date2.hour < end)
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           pos_tf = lower_timeframe;
           time_of_trade_open_sell[j] = Bars(symbols[j], lower_timeframe);
           time_of_trade_open_sell_time[j] = iTime(symbols[j], lower_timeframe, 0);
           prev_trade_signal_bar2[j] = bb_bar_sell[j];
           Print(" for sell |  first zz high = ",Bars(symbols[j], lower_timeframe) - zigzag_high_time[j],"  candle outside band = ",Bars(symbols[j], lower_timeframe) - bb_bar_sell_sig[j],"  mtgl high = ",zigzagdown,"  sl = ",hhigh,"  div = ",Bars(symbols[j], lower_timeframe)-regular_buy_div_time[j],"");
           bb_sell_rsi[j] = false; 
           bb_sell_std[j] = false;
           trade_check2[j] = true;
           counter[j]++;
           
           high[j] = zigzagdown;
           low[j] = mrequest.price;
           if ( (SymbolInfoDouble(symbols[j],SYMBOL_ASK) >= high[j]) )
           {
              if(martingale_exit1 == true)
              setorder(POSITION_TYPE_BUY, symbols[j], j);
           }
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
  }
  


if(PositionsTotal() > 0 && martingale_exit1 == true)
   {
     long latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       for(int i = 0; i < HistoryDealsTotal(); i++)
       {
       ulong ticket = HistoryDealGetTicket(i);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && HistoryDealGetString(ticket, DEAL_SYMBOL) == symbols[j])
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
       
     }
     
     datetime time_of_trade_open = time_of_trade_open_buy_time[j] > time_of_trade_open_sell_time[j] ? time_of_trade_open_buy_time[j]:time_of_trade_open_sell_time[j];
     if(latest_close > time_of_trade_open) //check if most recent close time is greater than time_of_open_trade2, if so then close all open orders
     {
       close_all(symbols[j], j);
     }
       
   }
   
 //closing when total profit is 0 only when the breakeven exit is allowed
   /*if(breakeven_exit == true && PositionsTotal() >= trades_for_breakeven) //i hv not made this correctly... i will not try to fix it now, its not important
   { 
     if(profit_total() >= 0)
     {
       close_all();
     }
   }*/

  
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
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}

if (use_zz2 == true)
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, timeframe, 
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}
          
if (use_zz3 == true) 
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, timeframe, 
           regular_buy_div_time[j], regular_sell_div_time[j], found_reg_sell_div, found_reg_buy_div, regular_buy_div_time_ht[j], regular_sell_div_time_ht[j], symbols[j]);
}
  

  if ( PositionSelect(symbols[j]) ) 
  {
    
    for(int i = PositionsTotal()-1; i >= 0; i--)
    {
    ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double point = SymbolInfoDouble(symbols[j],SYMBOL_POINT); 
    
    if ( type == POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == symbols[j])
    {
      if ( iClose(symbols[j], pos_tf, 0) >= (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) && allow_breakeven_sl == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = symbols[j];
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) + ((breakeven_pips*10) * point); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         bool res = OrderSend(mrequest, mresult);
      }
      
      if ( allow_div_based_close == true && found_reg_sell_div == true && regular_sell_div_time_ht[j] >= time_of_trade_open_buy_time[j] )
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
      
      int han1 = iBands(symbols[j], lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
      int han2 = iBands(symbols[j], lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
      double han1_buff[], han2_buff[];
      CopyBuffer(han1, 2, 0, 1, han1_buff);
      CopyBuffer(han2, 2, 0, 1, han2_buff);
      ArraySetAsSeries(han1_buff, true);
      ArraySetAsSeries(han2_buff, true);
      
      if ( allow_outer_band_cross_close == true && (iLow(symbols[j], lower_timeframe, 0) < han1_buff[0] || iLow(symbols[j], lower_timeframe, 0) < han2_buff[0]) && PositionGetDouble(POSITION_PROFIT) > 0 )
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
    
    
    if ( type == POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == symbols[j])
    {
      if ( iClose(symbols[j], pos_tf, 0) <= (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) && allow_breakeven_sl == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = symbols[j];
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN) - ((breakeven_pips*10) * point); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         bool res = OrderSend(mrequest, mresult);
      } 
      
      if ( allow_div_based_close == true && found_reg_buy_div == true && regular_buy_div_time_ht[j] >= time_of_trade_open_sell_time[j] )
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
      
      int han1 = iBands(symbols[j], lower_timeframe, bbmaperiod, 0, bb_dev, bbappliedprice);
      int han2 = iBands(symbols[j], lower_timeframe, bbmaperiod2, 0, bb_dev2, bbappliedprice2);
      double han1_buff[], han2_buff[];
      CopyBuffer(han1, 1, 0, 1, han1_buff);
      CopyBuffer(han2, 1, 0, 1, han2_buff);
      ArraySetAsSeries(han1_buff, true);
      ArraySetAsSeries(han2_buff, true);
      
       if ( allow_outer_band_cross_close == true && (iHigh(symbols[j], lower_timeframe, 0) > han1_buff[0] || iHigh(symbols[j], lower_timeframe, 0) > han2_buff[0]) && PositionGetDouble(POSITION_PROFIT) > 0 )
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
    
  }
  



void setorder(ENUM_POSITION_TYPE order_type, string symb, int j) //sets pending orders with doubles lotsize and correct order type and entry price
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
         request.volume = PositionGetDouble(POSITION_VOLUME)*2;                                            
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
           modify(symb, j);
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           close_all(symb, j);
           ResetLastError();
         }

  
} 

//modify
void modify(string symbol, int j)
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
         if(PositionSelect(symbol)) 
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
           high[j] = PositionGetDouble(POSITION_PRICE_OPEN);
           else
           low[j] = PositionGetDouble(POSITION_PRICE_OPEN);
         }
         else 
         {
           Print("The modify order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
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

void close_all(string symb, int j)
{
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  
  for(int i = 0; i < PositionsTotal(); i++)
     {
         ulong ticket = PositionGetTicket(i);
         
         if(PositionGetSymbol(i) == symb)
         {
         long digits = SymbolInfoInteger(symb, SYMBOL_DIGITS);
         double entry_price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_BID), digits):NormalizeDouble(SymbolInfoDouble(symb,SYMBOL_ASK), digits);  
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
           //trade_close_shift[j] = Bars(symb, PERIOD_CURRENT) - 0;
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

  
double maxRSIValue(int from, int to, ENUM_TIMEFRAMES tf, string symb)
  {
   double max_first_rsi=0;
   int handle = iRSI(symb, tf, 14, PRICE_CLOSE);
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
datetime maxRSITime(int from, int to, ENUM_TIMEFRAMES tf, string symb)
  {
   double max_first_rsi=0;
   datetime maxtime=currentTime();
   int handle = iRSI(symb, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(max_first_rsi < rsi[i])
        {
         max_first_rsi = rsi[i];
         maxtime = iTime(symb,tf,i);
        }
     }
   return maxtime;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double minRSIValue(int from, int to, ENUM_TIMEFRAMES tf, string symb)
  {
   double min_first_rsi=45356443455;
   int handle = iRSI(symb, tf, 14, PRICE_CLOSE);
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
datetime minRSITime(int from, int to, ENUM_TIMEFRAMES tf, string symb)
  {
   double min_first_rsi=45356443455;
   datetime mintime= currentTime();
   int handle = iRSI(symb, tf, 14, PRICE_CLOSE);
   double rsi[];
   CopyBuffer(handle, 0, from, (to - from)+1, rsi);
   ArraySetAsSeries(rsi, true);
   for(int i = 0 ; i<=ArraySize(rsi)-1; i++)
     {
      if(min_first_rsi > rsi[i])
        {
         min_first_rsi = rsi[i];
         mintime = iTime(symb,tf,i);
        }
     }
   return mintime;
  }
