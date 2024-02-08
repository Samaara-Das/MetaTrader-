//+------------------------------------------------------------------+
//|                                ma_cross_hid_div_mtgl netting.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <multidiv.mqh>

#include <ZonePosition.mqh>
#define ZPClass CZonePosition

//EA LOGIC DESCRIPTION : rsi hidden divergence and ma cross. (the ma conditions are optional)
//heiken ashi candle for entry. buy logic: if the candle is white and there is no lower wick
//sell logic: if the candle is red and there is no upper wick

//zz low/high and 1st divergence high/low are used for the sl. for tp, risk-reward and fixed tp are used
//uses multi degree divergence's and the latest one is used for entry

//added zz4_shift for the shift to start looking for zz high/lows for sl and mtgl1 to avoid putting sl at
//zz high/low which is at shift 0

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. 
//netting will start based on wherever the sl level is for the first trade. 

//removed breakeven exit from the inputs, because it's not needed in the strategy

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql4.mqh file, you must compile this ea also

//IMPORTANT : compile ea before use to get the latest changes made in included mqh files

#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

input string ____ = " "; //  

enum chooseStoploss
  {
     zigzag_sl, //ZigZag based stoploss 
     div_sl //Divergence based stoploss 
  };
  
enum chooseTakeprofit
  {
     tp_fixd, //Fixed TakeProfit
     tp_rsk_rwrd //Risk-Reward TakeProfit
  };

input string zz_param = " "; //Fill Waverunner Parameters
input int zz_arrow_depth = 12; //First Depth for Divergence
input int zz_arrow_deviation = 5; //First Deviation for Divergence
input int zz_arrow_backStep = 3; //First Backstep for Divergence
input bool use_zz = true; //Use First Waverunner for Divergence
input string a1 = " "; // _
input int zz_arrow_depth2 = 8; //Second Depth for Divergence
input int zz_arrow_deviation2 = 5; //Second Deviation for Divergence
input int zz_arrow_backStep2 = 3; //Second Backstep for Divergence
input bool use_zz2 = true; //Use Second Waverunner for Divergence
input string b2 = " "; // _
input int zz_arrow_depth3 = 3; //Third Depth for Divergence
input int zz_arrow_deviation3 = 2; //Third Depth for Divergence
input int zz_arrow_backStep3 = 2; //Third Depth for Divergence
input bool use_zz3 = true; //Use Third Waverunner for Divergence
input string c3 = " "; // _
input int zz_arrow_depth4 = 12; //Fourth Depth for Waverunner Sl
input int zz_arrow_deviation4 = 5; //Fourth Depth for Waverunner Sl
input int zz_arrow_backStep4 = 3; //Fourth Depth for Waverunner Sl
input int zz4_shift = 0; //Waverunner Shift(shift to start looking for zz highs/lows for sl)
input string blank1 = " "; // _
input int fonts = 13; //Font Size of Label
input color bear_color = clrRed; //Colour of Bearish Div
input color bull_color = clrLime; //Colour of Bullish Div
input int div_lookback = 100; //Lookback for Divergence

input string __ = " "; // _
input string d4 = " "; // _

//param for ma
input string ma_param = " "; //EMA Parameters
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //EMA Applied Price
input ENUM_MA_METHOD ma_methodd = MODE_EMA; //EMA Method
input int ma_periodd_slow = 200; //Slow EMA Period
input int ma_periodd_fast = 50; //Fast EMA Period

input string blank2 = " "; //_
input string e5 = " "; // _

//parameters for heiken ashi
input string heiken_param = " "; //Heiken Parameters
input color ExtColor1 = Red;    // Shadow of bear candlestick
input color ExtColor2 = White;  // Shadow of bull candlestick
input color ExtColor3 = Red;    // Bear candlestick body
input color ExtColor4 = White;  // Bull candlestick body

input string jt = " "; //_
input string fg = " "; //_

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input string sl_note = " "; // Fill Stoploss & TakeProfit Inputs
input bool heiken_close = false; //Heiken Ashi Close Exit
input string le = " "; //_
input chooseStoploss sl_choice = div_sl; //StopLoss Choice
input chooseTakeprofit tp_choice = tp_rsk_rwrd; //Takeprofit Choice
input string i9 = " "; // _
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double tp_ratio = 2; //Risk-Reward Ratio for Takeprofit

input string blank = " "; //_
input string de = " "; //_

input string mtgl_note = " "; //Fill MArtingale Inputs Below
input bool allow_mtgl = true; //Allow Martingale
input double risk_reward_tp = 2; //Risk to Reward Ratio for mtgl
input double mtgl_multiplier = 0.01; //Martingale Multiplier
input int _slippage = 0; //slippage for pending orders in pips
input double swap = 0; //Swap for mtgl in pips
input double commission = 1; //Commission for mtgl in pips
input bool close_trades = true; //Close all trades when trade doesn't execute

input string gi = " "; //_
input string ef = " "; //_

input bool allow_ma = true; //Other General MA Conditions
input bool div_above_ma = false; //High/Low 2 of Divergence Above/Below Slow ma
input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int _start = 4; //Start Time of EA
input int end = 23; //End Time of EA

//the inputs below hv been removed, since they are not needed
bool first_trade_exit = true; //Allow First trade exit (uses zz swing high/low)  //not neeeded
 double first_trade_exit_ratio = 1; //First Trade Exit Ratio (for first trade only) 
bool breakeven_exit = false; //Breakeven Exit //not needed... they told me to remove it
 int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
bool sl_breakeven = false; //Allow SL to Move to Breakeven price
 bool first_hi_low = false; //Allow SL to be 1st ZZ high/low Based 
  bool sl_fixd = false; //Allow Fixed StopLoss
  
 double fixed_pips_sl = 10; //Pips for Fixed StopLoss
 double pips_for_sl = 0; //Amount of pips to be added/subtracted from stoploss
 double breakeven_ratio = 1; // Breakeven Ratio
 double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price

int stat_ticket;
int ma_handle, ma_handle2, hkn_ashi_handle, zz_handle, zz_handle2, counter = 0;
datetime bullish_cross, bearish_cross, heiken_bull, heiken_bear, trade_close_shift;
double div_reg[], div_hid[], low_of_hid_bull, high_of_hid_bear, low_of_hid_bull2, high_of_hid_bear2;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime hid_bull_div_time, hid_bear_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp;
double high3, low3, percent_counter = 0;
bool trade_check = false;
datetime history_start = TimeCurrent();

ZPClass *ZonePosition;

int OnInit(void)
{
   if(allow_mtgl)
   {
     ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, 0.0, 0.0, _slippage);   
   }
   
   return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{
  delete ZonePosition;
}



void OnTick()
{
   
   MqlTick latest_price;
   SymbolInfoTick(_Symbol, latest_price);
   MqlDateTime date;
   TimeCurrent(date);
   
   if(allow_mtgl)
   {
     bool reached = false;
     ZonePosition.OnTick(reached);     
   }
  
   
   double ma_fast1, ma_slow1, ma_fast2, ma_slow2, ma_slow3; //ma_slow3 is meant for div_above_ma condition, the rest are for checking ma cross 
   ma_fast1 = iMA(_Symbol, lower_timeframe, ma_periodd_fast, 0, ma_methodd, ma_appliedprice, 1);
   ma_slow1 = iMA(_Symbol, lower_timeframe, ma_periodd_slow, 0, ma_methodd, ma_appliedprice, 1);
   
   ma_fast2 = iMA(_Symbol, lower_timeframe, ma_periodd_fast, 0, ma_methodd, ma_appliedprice, 2);
   ma_slow2 = iMA(_Symbol, lower_timeframe, ma_periodd_slow, 0, ma_methodd, ma_appliedprice, 2);
  
   //if the close > open, its a white candle. if the open > close, its a red candle
   double open, low=0, high=0, close, candle;
   close  = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 3, 1);
   open   = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 2, 1);
   
   if(close > open) 
   {
     double val1 = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 0, 1);
     double val2 = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 1, 1);
     low = MathMin(val1, val2);
     high = MathMax(val1, val2);
     candle = 0;
   }
   
   if(close < open)
   {
     double val1 = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 0, 1);
     double val2 = iCustom(_Symbol, lower_timeframe, "Heiken Ashi", ExtColor1, ExtColor2, ExtColor3, ExtColor4, 1, 1);
     low = MathMin(val1, val2);
     high = MathMax(val1, val2);
     candle = 1;
   }
  
  
if (use_zz == true)   //for hidden divergence
{
hidden_divergence(zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, div_lookback,
          high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
           hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 1, bear_color, bull_color, fonts);
}

if (use_zz2 == true)  //for hidden divergence
{
hidden_divergence(zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, div_lookback,
           high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
           hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 1, bear_color, bull_color, fonts);
}
          
if (use_zz3 == true) //for hidden divergence
{
hidden_divergence(zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, div_lookback,
           high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
           hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 1, bear_color, bull_color, fonts);
}
     
   
 
 double zigzagup=0;
 double zigzagdown=0;
 datetime zigzagdowntime=NULL;
 datetime zigzaguptime = NULL;
 int two_up=0,two_down=0,two_up2=0,two_down2=0;
 int end_shift = zz4_shift + 50;
   
   for(int i= zz4_shift; i<end_shift; i++)
     {
      double downarrow=iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 3, i);  // up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime = iTime(_Symbol,lower_timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         //Print("found zz down time = ",zigzagdowntime," on shift ",i,"");
         break;
        }
     }
 
   end_shift = zz4_shift + 50;
   for(int i= zz4_shift; i<end_shift; i++)
     {
      double uparrow=iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 2, i); // down val
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime = iTime(_Symbol,lower_timeframe,i);
         zigzagup = uparrow;
         two_up = i;
         break;
        }
     }
     //-------

 
   if (trade_check == true && hasMarketOrder() == false)
   {
   trade_check = false;
   trade_close_shift = iTime(_Symbol, lower_timeframe, 0);
   }

   
   if(ma_fast2 > ma_slow2 && ma_slow1 > ma_fast1)
   bearish_cross = iTime(_Symbol, lower_timeframe, 1);
  
   
   if(candle == 1 && high == open )
   heiken_bear = iTime(_Symbol, lower_timeframe, 1);
//   if(open < close && candle == 1) Print("high = ",high," close=",close,"");
//   if(open > close && candle == 1)  Print("high = ",high," open=",open,"");
  
   //Print("candle = ",candle," high = ",high," low = ",low," close = ",close," open = ",open,"");
  
   int highest_ind = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, hid_bear_div_time), 1);
   double highest = iHigh(_Symbol, lower_timeframe, highest_ind);
   
   int highest_ind1 = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, hid_bear_div_curr_time), 1);
   double highest1 = iHigh(_Symbol, lower_timeframe, highest_ind1);
   
   ma_slow3 = iMA(_Symbol, lower_timeframe, ma_periodd_slow, 0, ma_methodd, ma_appliedprice, iBarShift(_Symbol, lower_timeframe, hid_bear_div_curr_time));
   bool ma_check = ( (div_above_ma == true && ma_slow3 > high_of_hid_bear2) || (div_above_ma == false) );
   bool main_ma_check = ((bearish_cross != 0 && hid_bear_div_curr_time >= bearish_cross && ma_slow1 > ma_fast1 && allow_ma) || (!allow_ma));
    
   //Print("sell cond1= ",trade_close_shift <= hid_bear_div_curr_time,"  cond2 = ",hid_bear_div_time != 0 && bearish_cross != 0,"  cond3 = ",hid_bear_div_curr_time >= bearish_cross,"  cond4 = ",heiken_bear >= hid_bear_div_curr_time,"  cond5 = ",hid_bear_div_time != prev_hid_bear_div_time,"");  
   //Print("sell cond6 = ",highest == high_of_hid_bear,"  cond7 = ",highest1 == high_of_hid_bear2,"  cond8 = ",ma_slow1 > ma_fast1,"  cond9 = ",ma_check == true,"  heiekn = ",heiken_bear," hid currnet = ",hid_bear_div_curr_time,""); 
   if(trade_close_shift <= hid_bear_div_curr_time && hid_bear_div_time != 0 && heiken_bear >= hid_bear_div_curr_time && hasMarketOrder() == false && hid_bear_div_time != prev_hid_bear_div_time && 
      highest == high_of_hid_bear && highest1 == high_of_hid_bear2 && ma_check == true && main_ma_check == true)
   {                             
         double price = NormalizeDouble(latest_price.bid,_Digits);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = sl_choice == zigzag_sl ? zigzagdown : sl_choice == div_sl ? high_of_hid_bear : 0; 
         double pips = (slt > price ? slt - price:price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = MathFloor(Lots * 100) / 100;
         
         double sl = slt != 0 ? slt + (_Point*(pips_for_sl*10)):0;
         double tp = tp_choice == tp_rsk_rwrd ? NormalizeDouble(price - ( price > sl ? ((price - sl) * tp_ratio) : ((sl - price) * tp_ratio) ), _Digits) : tp_choice == tp_fixd ? price - (_Point*(fixed_pips_tp*10)): 0;
                                            
         double volume = use_inital_lots == true ? inital_lots:Lots;                                             
         
         if(date.hour >= _start && date.hour < end )
         stat_ticket = OrderSend(_Symbol, OP_SELL, volume, price, 100, sl, tp, "sell");
       
         if(stat_ticket > 0) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bear_div_time = hid_bear_div_time;
           high3 = sl;
           low3 = price;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           
           Print(" hid div 2nd high = ",high_of_hid_bear," time of hid div = ",hid_bear_div_curr_time,"  ma slow2 = ",ma_slow2,"  1% risk lotsize = ",Lots,"");
           trade_check = true;
           
           if(allow_mtgl)
           {
             ZonePosition = new ZPClass((high3 - low3)*risk_reward_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(stat_ticket);
           }
          
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
           
         }
   }
   
   
  
   if(ma_slow2 > ma_fast2 && ma_fast1 > ma_slow1)
   bullish_cross = iTime(_Symbol, lower_timeframe, 1);

   if(candle == 0 && low == open )
   heiken_bull = iTime(_Symbol, lower_timeframe, 1);
   
   int lowest_ind = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, hid_bull_div_time), 1);
   double lowest = iLow(_Symbol, lower_timeframe, lowest_ind);
   
   int lowest_ind1 = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, hid_bull_div_curr_time), 1);
   double lowest1 = iLow(_Symbol, lower_timeframe, lowest_ind1);
   
   ma_slow3 = iMA(_Symbol, lower_timeframe, ma_periodd_slow, 0, ma_methodd, ma_appliedprice, iBarShift(_Symbol, lower_timeframe, hid_bear_div_curr_time));
   ma_check = ( (div_above_ma == true && ma_slow3 < low_of_hid_bull2) || (div_above_ma == false) );
   main_ma_check = ((bullish_cross != 0 && hid_bull_div_curr_time >= bullish_cross && ma_fast1 > ma_slow1 && allow_ma) || (!allow_ma));
   
   //Print("low = ",low,"  open = ",open,"  ",low == open,"");
   //Print("buy cond1 = ",trade_close_shift <= hid_bull_div_curr_time,"  cond2 = ",hid_bull_div_time != 0,"  cond3 = ",heiken_bull >= hid_bull_div_curr_time,"  cond4 = ",hid_bull_div_time != prev_hid_bull_div_time,""); 
   //Print("buy cond5 = ",lowest == low_of_hid_bull,"  cond6 = ",lowest1 == low_of_hid_bull2," cond7 = ",ma_check == true,"  cond8 = ",ma_check == true,"");
   
   if (trade_close_shift <= hid_bull_div_curr_time && hid_bull_div_time != 0 && heiken_bull >= hid_bull_div_curr_time && hasMarketOrder() == false && hid_bull_div_time != prev_hid_bull_div_time &&
       lowest == low_of_hid_bull && lowest1 == low_of_hid_bull2 && ma_check == true && main_ma_check == true)
   {
         double price = NormalizeDouble(latest_price.ask,_Digits);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = sl_choice == zigzag_sl ? zigzagup : sl_choice == div_sl ? low_of_hid_bull : 0; 
         double pips = (price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = MathFloor(Lots * 100) / 100;
         
         double sl = slt != 0 ? slt - (_Point*(pips_for_sl*10)):0;
         double tp = tp_choice == tp_rsk_rwrd ? NormalizeDouble(price + ( price > sl ? ((price - sl) * tp_ratio) : ((sl - price) * tp_ratio) ), _Digits) : tp_choice == tp_fixd ? price + (_Point*(fixed_pips_tp*10)): 0;
                                       
         double volume = use_inital_lots == true ? inital_lots:Lots;                                             
         
         if(date.hour >= _start && date.hour < end)
         stat_ticket = OrderSend(_Symbol, OP_BUY, volume, price, 100, sl, tp, "buy");
         
         if(stat_ticket > 0) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bull_div_time = hid_bull_div_time;
           high3 = price;
           low3 = sl;
           history_start = iTime(_Symbol, lower_timeframe, 0);
        
           Print("hid div = ",hid_bull_div_curr_time,"  ma slow2 = ",ma_slow2,"  1% risk lotsize = ",Lots,"");
           trade_check = true;
           
           if(allow_mtgl)
           {
             ZonePosition = new ZPClass((high3 - low3)*risk_reward_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(stat_ticket);
           }

         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
           
         }
   }
   
   
   
int count = 0;  
for(int i = 0; i < OrdersTotal(); i++)
{ 
  if(OrderSelect(i, SELECT_BY_POS))
  {
    if(OrderSymbol() == _Symbol)
    count++; 
  }
            
} 
   
 
   //closing when total profit is 0 only when the breakeven exit is allowed
   //if(breakeven_exit == true && count >= trades_for_breakeven)  //this is not needed in this strategy
   //{ 
   //  if(profit_total(_Symbol) >= 0)
   //  {
   //    close_all(_Symbol);
   //  }
   //}
 
 
 
    for(int i = OrdersTotal()-1; i >= 0; i--)
    {
      if(OrderSelect(i, SELECT_BY_POS))
      {
          int type=OrderType();
          if ( type == OP_BUY && OrderSymbol() == _Symbol && OrderTicket() == stat_ticket )
          {
      //      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      //      {
      //         mrequest.action = TRADE_ACTION_SLTP;
      //         mrequest.position = PositionGetInteger(POSITION_TICKET);
      //         mrequest.symbol = _Symbol;
      //         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
      //         mrequest.tp = PositionGetDouble(POSITION_TP);
      //      
      //         bool res = OrderSend(mrequest, mresult);
      //      }
            
            if ( candle == 1 && heiken_close == true ) 
            {
               int res = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
               if(res < 0) Print("could not close buy order when heikan ashi was red.  error: ",GetLastError());
            }
          }
          
          if ( type == OP_SELL && OrderSymbol() == _Symbol && OrderTicket() == stat_ticket )
          {
      //      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      //      {
      //         mrequest.action = TRADE_ACTION_SLTP;
      //         mrequest.position = PositionGetTicket(i);
      //         mrequest.symbol = _Symbol;
      //         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
      //         mrequest.tp = PositionGetDouble(POSITION_TP); 
      //      
      //         bool res = OrderSend(mrequest, mresult);
      //      } 
          
            if ( candle == 0 && heiken_close == true ) 
            {
               int res = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
               if(res < 0) Print("could not close buy order when heikan ashi was blue.  error: ",GetLastError());
            }
            
          }
      }
    }
   
}


bool hasMarketOrder() {
   for (int i=OrdersTotal()-1; i >= 0; i--) {
      if(OrderSelect(i,SELECT_BY_POS)) {
         if (OrderSymbol() == _Symbol && (OrderType()==OP_SELL || OrderType()==OP_BUY)){
            return true;
            break;
         }
      }
   }
   return false;
}


double profit_total(string symb)
{
  double profit = 0.0;
  for (int i = 0; i < OrdersTotal(); i++)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) // Select the i-th order in the Trade tab
    {
       if (OrderSymbol() == _Symbol) // Check the symbol of the order
       {
         profit += OrderProfit(); // Add the profit of the order to the total profit
       }
    }
  }
  
  return profit;
}


void close_all(string symb)
{
  
  for(int i = OrdersTotal()-1; i >= 0; i--)
     {
    
         if(OrderSelect(i,SELECT_BY_POS))
         {
            bool res = false;
            if(OrderSymbol() == _Symbol)
            res = OrderClose(OrderTicket(), OrderLots(), OrderType()==OP_BUY ? Bid:Ask, 100);
            
            if(res) //Request is completed or order placed
            {
              Print("closed trade successfully");
              trade_close_shift = Bars- 0;
            }
            else
            {
              Print("The closing order request could not be completed -error:",GetLastError());
              ResetLastError();
            }
         }
     }
}





