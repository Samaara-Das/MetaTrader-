//+------------------------------------------------------------------+
//|                                      MAcross_SD_mtgl netting.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <ZonePosition.mqh>
#define ZPClass CZonePosition

#resource "\\Indicators\\ZigZag.ex4"

//EA Description : MA cross with stdDev above its moving average and zigzag for sl and risk-reward for tp with martingale added
//with option added to keep 1:1 risk-reward ratio for first trade and after that trade, tp and sl will be risk-reward based

//if there has been an ma cross (bullish or bearish), it will wait for certain number of bars after the cross to find
//stdDev's ma above stdDev line.
//the certain number of bars it will wait for will be specified in the inputs. 
//"Number of Candles to wait for signal" is the input where you can specify number of bars to wait. 

//added zz4_shift for the shift to start looking for zz high/lows for sl and mtgl1 to avoid putting sl at
//zz high/low which is at shift 0
//added lookback range for the zigzag to find zz highs/lows

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. 

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql4.mqh file, you must compile this ea also

//IMPORTANT : compile ea before use to get the latest changes made in included mqh files

//std parameters
input string std_param = " "; //Fill Standard Deviation Parameters
input int std_period = 20; //Period
input ENUM_MA_METHOD std_method = MODE_EMA; //Method
input ENUM_APPLIED_PRICE std_appliedprice = PRICE_CLOSE; //Applied price
int std_handle;
double std_buffer[];
//ma parameters (std's ma)
input string std_ma_param = " "; //Fill StdDev's Moving Average
input int std_ma_period = 55; //Period
input ENUM_MA_METHOD std_ma_method = MODE_EMA; //Method
int std_ma_handle;
double std_ma_buffer[];

input string blank1 = " "; // " "

//ma parameters 
input string ma_param = " "; //Fill Moving Average Parameters
input int ma_slowperiod = 55; //Slow Period
input int ma_fastperiod = 21; //Fast Period
input ENUM_MA_METHOD ma_method = MODE_EMA; //Method
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //Applied Price
double ma_fast_buffer[], ma_slow_buffer[];

input string blank2 = " "; // " "

//zigzag parameters
input string zz_param = " "; //Fill ZigZag Parameters (for sl only)
input int zz_depth = 12; //Depth
input int zz_deviation = 5; //Deviation
input int zz_backstep = 3; //Backstep 
input int zz4_shift = 1; //ZigZag Shift(shift to start looking for zz highs/lows for sl)
input int lookback_range = 50; //lookback range
int zz_handle;
double zz_col[], zz_low[], zz_high[];

input string blank3 = " "; // " "

//ea parameters
//add lotsize as per equity
input int candles = 2; //Number of Candles to wait for signal
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input double inital_lots = 0.01; //Initial Lots
input double max_pips = 50; //Max Pips
input double swap = 0; //Swap for mtgl in pips
input double commission = 0; //Commission for mtgl in pips
input int _slippage = 0; //slippage for pending orders in pips

input string blank4 = " "; // " "

input bool first_trade_exit = true; //First Trade Exit 
input bool fixed_pip_exit = false; //Fixed pip Exit (tp only)
input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

input string blank5 = " "; // " "

input double first_trade_exit_ratio = 1; //First Trade Exit Ratio (for first trade only) 
input double risk_reward_tp = 2; //Risk to Reward Ratio for mtgl
input double mtgl_multiplier = 0.01; //Martingale Multiplier
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input ENUM_TIMEFRAMES timeframe = PERIOD_M5; //Choose timeframe for trades (DO NOT CHOOSE PERIOD_CURRENT)
input int start_time = 4; //Start Time of EA
input int end_time = 23; //End Time of EA

static string _mSymbol;
   
static double _mInitialPrice;
static double _mInitialVolume;
static double _mMultiplier;
static double _mPrevLots;
static long   _mMagicNumber;
static string _mTradeComment;
static datetime  _mTradeOpen;
static double _mTakeprofit;
   
static int  _mTickets[];
static int  _mDirection;
   
static double _mTarget;
static double _mZoneSize;
static double _mSupplement;
static int _mSlippage;
   //double mVolProfit;
static double _volProfit[];
   
static double _mZoneHigh;
static double _mZoneLow;
static double _mTargetHigh;
static double _mTargetLow;

ZPClass *ZonePosition;

int OnInit()
{

//  if(hasMarketOrder()==true)
//  {
//    int ticket = 0;
//    ticket = marketTicket();
//    bool res = OrderSelect(ticket, SELECT_BY_TICKET);
//    
//    ZonePosition.mSymbol = OrderSymbol();
//    ZonePosition.mInitialPrice = OrderOpenPrice();
//    //mInitialVolume does not need to be filled. it is used in prevlots only. so prevlots will have mInitialVolume
//    ZonePosition.mMultiplier = mtgl_multiplier;
//    ZonePosition.mPrevLots = OrderLots();
//    ZonePosition.mMagicNumber = OrderMagicNumber();
//    ZonePosition.mTradeComment = OrderComment();
//    ZonePosition.mTradeOpen = OrderOpenTime();
//    ZonePosition.mTakeprofit = OrderTakeProfit();
//    ZonePosition.mTpModify = false;
//   
//    
//    if(OrderLots() != inital_lots)
//    {
//      for(int i = OrdersHistoryTotal()-1; i>=0; i--)
//      {
//        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
//        {
//          if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL))
//          {
//            int size = ArraySize(ZonePosition.mTickets);
//            ArrayResize(ZonePosition.mTickets, size++);
//            ZonePosition.mTickets[size] = OrderTicket();
//            
//            if(OrderLots()==inital_lots)
//            break;
//          }
//        }
//      }
//    }
//    else
//    {
//      res = OrderSelect(ticket, SELECT_BY_TICKET);
//      ArrayResize(ZonePosition.mTickets, 0);
//      ZonePosition.mTickets[0] = OrderTicket();
//    }
//    
//    ticket = marketTicket();
//    
//    for(int i = 0; i < OrdersTotal(); i++)
//    {
//       if(OrderSelect(i, SELECT_BY_POS))
//       {
//         if(OrderSymbol() == _Symbol && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP))
//         ticket = OrderTicket();
//         break;
//       }
//    }
//    
//    res = OrderSelect(ticket, SELECT_BY_TICKET);
//    
//    int type = OrderType()==OP_BUYSTOP ? OP_BUY : OrderType()==OP_SELLSTOP ? OP_SELL : OrderType()==OP_BUY ? OP_BUY : OrderType()==OP_SELL ? OP_SELL : -1;
//    ZonePosition.mDirection = OrderType();
//    
//    if(hasPendingOrder())
//    {
//      double price1, price2;
//      
//      price2 = OrderOpenPrice();
//      
//      ticket = marketTicket();
//      res = OrderSelect(ticket, SELECT_BY_TICKET);
//      price1 = OrderOpenPrice();
//      
//      ZonePosition.mTarget = (price1 > price2 ? price1 - price2 : price2 - price1) * risk_reward_tp;
//      ZonePosition.mZoneSize = price1 > price2 ? price1 - price2 : price2 - price1;
//      //calculate zonesize and mtarget again because we have to get the exact open price of the 1st and 2nd trade. (if there have been 1st and 2nd trades)
//      
//      int market1_ticket = 0, market2_ticket = 0, inc = -1;
//      if(OrderLots() != inital_lots) //were ther more mtgl trades before the current trade
//      {
//        for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
//        {
//           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
//           {
//             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderLots()==inital_lots)
//             {
//               market1_ticket = OrderTicket();
//               inc = i;
//               break;
//             }
//           }
//        }
//        
//        for(int i = inc+1; i>=0; i++)
//        {
//           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
//           {
//             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderLots()!= inital_lots)
//             {
//               market2_ticket = OrderTicket();
//               break;
//             }
//           }
//        }
//        
//        res = OrderSelect(market1_ticket, SELECT_BY_TICKET,MODE_HISTORY);
//        price1 = OrderOpenPrice();
//        
//        res = OrderSelect(market2_ticket, SELECT_BY_TICKET,MODE_HISTORY);
//        price2 = OrderOpenPrice();
//        
//        ZonePosition.mZoneHigh = price1 >= price2 ? price1 : price2;
//        ZonePosition.mZoneLow = price1 <= price2 ? price1 : price2;
//        ZonePosition.mZoneSize = ZonePosition.mZoneHigh - ZonePosition.mZoneLow;
//        
//        ZonePosition.mTarget = ZonePosition.mZoneSize * risk_reward_tp;
//        ZonePosition.mTargetHigh = ZonePosition.mZoneHigh + ZonePosition.mTarget;
//        ZonePosition.mTargetLow = ZonePosition.mZoneLow - ZonePosition.mTarget;
//      }
//      
//    }
//    else 
//    {
//      ZonePosition.mTarget = 0;
//      ZonePosition.mZoneSize = 0;
//    }
//    
//    ticket = marketTicket();
//    res = OrderSelect(ticket, SELECT_BY_TICKET);
//    
//    //also calculate estimated loss for current open trade
//    int size = ArraySize(ZonePosition.volProfit);
//    ArrayResize(ZonePosition.volProfit, size+1);
//              
//    if(OrderType() == OP_SELL)
//    ZonePosition.volProfit[size] = ZonePosition.mPrevLots*(OrderOpenPrice() - ZonePosition.mZoneHigh);
//        
//    if(OrderType() == OP_BUY)
//    ZonePosition.volProfit[size] = ZonePosition.mPrevLots*(ZonePosition.mZoneLow - OrderOpenPrice());
//    
//    if(OrderLots() != inital_lots) //have there been previous mtgl trades before current running order
//    {
//      for(int i = OrdersHistoryTotal()-1; i >= 0; i--) //calculating booked loss of closed trades
//        { 
//           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) 
//           {
//            if(OrderLots()==inital_lots) //if we reach the first trade, no need to move on further to calculate losses for previous trades
//            {
//              //calculate mVolProfit
//              size = ArraySize(ZonePosition.volProfit);
//              ArrayResize(ZonePosition.volProfit, size+1);
//              ZonePosition.volProfit[size] = OrderType()==OP_BUY ? OrderLots()* (OrderClosePrice()-OrderOpenPrice()) : OrderLots()* (OrderOpenPrice()-OrderClosePrice());
//              break;
//            }
//           
//            if(OrderSymbol()==ZonePosition.mSymbol && (OrderType()==OP_BUY || OrderType()==OP_SELL))
//            {
//              type = OrderType();
//              double volume = OrderLots();
//              double closeprice = OrderClosePrice();
//              double openprice = OrderOpenPrice();
//              //calculate mVolProfit
//              size = ArraySize(ZonePosition.volProfit);
//              ArrayResize(ZonePosition.volProfit, size+1);
//              
//              if(type == OP_BUY)
//              ZonePosition.volProfit[size] = volume * (closeprice-openprice);
//          
//              if(type == OP_SELL)
//              ZonePosition.volProfit[size] = volume * (openprice-closeprice);
//              break;
//            }
//           } 
//        }
//    }
//    
//    ZonePosition.mSlippage = _slippage;
//    ZonePosition.mSupplement = ((swap*10) * _Point) + ((commission*10) * _Point);
//    ZonePosition.mStatus = ZONE_POSITION_STATUS_OPEN;
//    
//    
//  }
//  
//  else
  ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, 0.0, 0.0, _slippage);
  
  return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason)
{

  delete ZonePosition;
}

ulong stat_ticket;
int bullish_cross_shift, bearish_cross_shift, prev_bullish_cross_shift, prev_bearish_cross_shift;
int trade_close_shift, bullish_cross_shift_hr, bearish_cross_shift_hr, counter = 0, latest_cross;
bool trade_check = false;
double high, low, zigzagup_, zigzagdown_;
long time_of_trade_open;
datetime history_start = TimeCurrent();

void OnTick()
{
  MqlTick latest_price;
  MqlDateTime date;
  TimeCurrent(date);
  MqlDateTime date2;
  SymbolInfoTick(_Symbol, latest_price);
  
  bool reached = false;
  ZonePosition.OnTick(reached);
  
  ArraySetAsSeries(zz_col, true);
  ArraySetAsSeries(zz_high, true);
  ArraySetAsSeries(zz_low, true);
  
  ArrayResize(std_buffer, candles);
  for(int i = 1; i < candles+1; i++)
  {
    std_buffer[i-1] = iStdDev(_Symbol, timeframe, std_period, 0, std_method, std_appliedprice, i);
  }
  
  ArrayResize(std_ma_buffer, candles);
  for(int i = 1; i < candles+1; i++)
  {
    std_ma_buffer[i-1] = iMAOnArray(std_buffer, 0, std_ma_period, 0, std_ma_method, i);
  }
  
  ArraySetAsSeries(std_buffer, true);
  ArraySetAsSeries(std_ma_buffer, true);
  Print("std = ",std_buffer[0],"  ma std = ",std_ma_buffer[0]," ");
  
  //+------------------------------------------------------------------+
  //|   zigzag highs & lows                                            |
  //+------------------------------------------------------------------+
  
  
   double zigzagup=0;
   double zigzagdown=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   
   
   //---
   
   
   ArrayResize(ma_fast_buffer, 2);
   ArrayResize(ma_slow_buffer, 2);
   for(int i = 1; i < 3; i++)
   {
     ma_fast_buffer[i-1] = iMA(_Symbol, timeframe, ma_fastperiod, 0, ma_method, ma_appliedprice, i);
     ma_slow_buffer[i-1] = iMA(_Symbol, timeframe, ma_slowperiod, 0, ma_method, ma_appliedprice, i);
   }
   ArraySetAsSeries(ma_fast_buffer, true);
   ArraySetAsSeries(ma_slow_buffer, true);
   
  if (trade_check == true && hasMarketOrder() == false)
  {
  trade_check = false;
  trade_close_shift = Bars;
  } 
  
  
  
   if((ma_fast_buffer[1] < ma_slow_buffer[1] && ma_fast_buffer[0] > ma_slow_buffer[0]) || (ma_fast_buffer[1] > ma_slow_buffer[1] && ma_fast_buffer[0] < ma_slow_buffer[0]))
   latest_cross = Bars - 1;
  
  //+------------------------------------------------------------------+
  //|   buy condition                                                  |
  //+------------------------------------------------------------------+

  if(ma_fast_buffer[1] < ma_slow_buffer[1] && ma_fast_buffer[0] > ma_slow_buffer[0])
  bullish_cross_shift = Bars - 1;
  
  if(ma_fast_buffer[1] < ma_slow_buffer[1] && ma_fast_buffer[0] > ma_slow_buffer[0])
  {
  TimeToStruct(iTime(_Symbol, timeframe, 1), date2);
  bullish_cross_shift_hr = date2.hour;
  }
  
  int shift = Bars-bullish_cross_shift; //this is for where we start looking for a signal
  
  bool cond1 = false;
  
  if(bullish_cross_shift > 0)  //this is the old way of writing the buy logic. this is written correctly... just not simple for me to understand
  {
  for(int i = shift; i >= 1; i--)
  {
    if((Bars-1) <= ((bullish_cross_shift + candles)-1)) 
    {
      if(std_buffer[i-1] > std_ma_buffer[i-1] && i-1 == 0 && trade_close_shift < bullish_cross_shift && bullish_cross_shift == latest_cross)
      {
        //Print(" for buy | std condition got fullfilled at index = ",i-1,"  val of std = ",std_buffer[i-1],"  val of std ma = ",std_ma_buffer[i-1],"");
        cond1 = true; 
        for(int s = 0; s < ArraySize(std_ma_buffer); s++)
        {
          //Alert("",std_ma_buffer[s],"");
        }
      }    
    }
    else
    {
      break;
    }
  }
  }
  
   
  
  
  //+------------------------------------------------------------------+
  //|   sell condition                                                 |
  //+------------------------------------------------------------------+
  
  if(ma_fast_buffer[1] > ma_slow_buffer[1] && ma_fast_buffer[0] < ma_slow_buffer[0])
  bearish_cross_shift = Bars - 1;
  
  if(ma_fast_buffer[1] > ma_slow_buffer[1] && ma_fast_buffer[0] < ma_slow_buffer[0])
  {
  TimeToStruct(iTime(_Symbol, timeframe, 1), date2);
  bearish_cross_shift_hr = date2.hour;
  }
  
  int shift1 = Bars-bearish_cross_shift; //this is for where we start looking for a signal
  
  bool cond2 = false;
  
  if(bearish_cross_shift > 0) //this is the old way of writing the buy logic. this is written correctly... just not simple for me to understand
  {
  for(int i = shift1; i >= 1; i--)
  {
   
    if((Bars-1) <= ((bearish_cross_shift + candles)-1)) 
    {
      if((std_buffer[i-1] > std_ma_buffer[i-1] /*|| std_buffer[i-1] < std_ma_buffer[i-1]*/) && i-1 == 0 && trade_close_shift < bearish_cross_shift && bearish_cross_shift == latest_cross)
      {
        cond2 = true;
        //Print(" for sell | std condition got fullfilled at index = ",i-1,"  val of std = ",std_buffer[i-1],"  val of std ma = ",std_ma_buffer[i-1],"");
        for(int s = 0; s < ArraySize(std_ma_buffer); s++)
        {
          //Alert("",std_ma_buffer[s],"");
        }
      }     
    }
    else
    {
      break;
    }
  }
  }


  //+------------------------------------------------------------------+
  //|   opening trades                                                 |
  //+------------------------------------------------------------------+
  
  
  if (cond1 && hasMarketOrder() == false && prev_bullish_cross_shift != bullish_cross_shift && date.hour >= start_time && date.hour < end_time) // && trade_close_shift[j] < bullish_cross_shift[j] //try adding this piece of code, i got it from multi-currency version of this ea
  { 
        ArrayResize(zz_high, lookback_range);
        ArrayResize(zz_low, lookback_range);
        ArrayResize(zz_col, lookback_range);
        for(int i = 0; i < lookback_range; i++)
        {
          zz_high[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 1, i);
          zz_low[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 2, i);
          zz_col[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 0, i);
        }
  
         for(int i= zz4_shift ; i<lookback_range; i++)
          {
            double downarrow=zz_high[i]; //up val
            double zero=zz_col[i];
            if(downarrow>0 && zero > 0)
              {
               zigzagdowntime = iTime(_Symbol,timeframe,i);
               zigzagdown = downarrow;
               two_down = i;
               break;
              }
          }
  
         for(int i= zz4_shift ; i<lookback_range; i++)
          {
            double uparrow=zz_low[i]; //down val
            double zero=zz_col[i];
            if(uparrow>0 && zero > 0)
              {
               zigzaguptime = iTime(_Symbol,timeframe,i);
               zigzagup = uparrow;
                two_up = i;
               break;
              }
          }
      
         int barshift = iBarShift(_Symbol, timeframe, zigzaguptime);
         barshift = barshift <= 0 ? 1:barshift;
         
         ArrayResize(ma_fast_buffer, barshift);
         ArrayResize(ma_slow_buffer, barshift);
         for(int i = 0; i < barshift; i++)
         {
           ma_fast_buffer[i] = iMA(_Symbol, timeframe, ma_fastperiod, 0, ma_method, ma_appliedprice, i);
           ma_slow_buffer[i] = iMA(_Symbol, timeframe, ma_slowperiod, 0, ma_method, ma_appliedprice, i);
         }
        
         if(ma_slow_buffer[barshift- 1] > ma_fast_buffer[barshift- 1] && zigzaguptime <= zigzagdowntime) //for buy
         zigzagdown_ = zigzagup;
         Print("zigzagdown_  = ", zigzagdown_);
         //---
  
         double sl2 = 0;
         double tp2 = NormalizeDouble(latest_price.ask + ( zigzagdown_ > latest_price.ask ? (zigzagdown_ - latest_price.ask)*first_trade_exit_ratio : (latest_price.ask - zigzagdown_)*first_trade_exit_ratio ), _Digits);
         
         double sl = first_trade_exit ? sl2 : 0;
         double tp = first_trade_exit ? tp2 : fixed_pip_exit ? latest_price.ask + (_Point*(fixed_pips_tp*10)) : 0;
         
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double pips = (latest_price.ask - sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;

         
         bool res = false;
         if(pip_range(latest_price.ask, zigzagdown_) == true)
         res = OrderSend(_Symbol, OP_BUY, use_inital_lots == true ? inital_lots:Lots, latest_price.ask, 100, sl, tp, "BUY Trade");
         
          if(res) //Request is completed or order placed
         {
         
            Print(" trade close = ",Bars(_Symbol,PERIOD_CURRENT)-trade_close_shift,"  cross = ",Bars(_Symbol,PERIOD_CURRENT)-bullish_cross_shift,"  ma fast = ",ma_fast_buffer[0],"  ma slow  =",ma_slow_buffer[0],"");
            prev_bullish_cross_shift = bullish_cross_shift;
            high = latest_price.ask;
            low = zigzagdown_;
            time_of_trade_open = iTime(_Symbol, timeframe, 0);
            history_start = iTime(_Symbol, timeframe, 0);
            
            int ticket = 0;
            for(int i = OrdersTotal()-1; i >= 0; i--)
            {
              if(OrderSelect(i, SELECT_BY_POS))
              {
                ticket = OrderTicket();
                stat_ticket = ticket;
                if(OrderSymbol() == _Symbol)
                break;
              }
            }
            
            ZonePosition = new ZPClass((high - low)*risk_reward_tp, high - low, mtgl_multiplier, swap, commission, _slippage);
            ZonePosition.OpenPosition(ticket);
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }
  
  if (cond2 && hasMarketOrder() == false && prev_bearish_cross_shift != bearish_cross_shift && date.hour >= start_time && date.hour < end_time)
  {
        ArrayResize(zz_high, lookback_range);
        ArrayResize(zz_low, lookback_range);
        ArrayResize(zz_col, lookback_range);
        for(int i = 0; i < lookback_range; i++)
        {
          zz_high[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 1, i);
          zz_low[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 2, i);
          zz_col[i] = iCustom(_Symbol, timeframe, "ZigZag", zz_depth, zz_deviation, zz_backstep, 0, i);
        }
  
        for(int i= zz4_shift ; i<lookback_range; i++)
          {
            double uparrow=zz_low[i]; //down val
            double zero=zz_col[i];
            if(uparrow>0 && zero > 0)
              {
               zigzaguptime = iTime(_Symbol,timeframe,i);
               zigzagup = uparrow;
                two_up = i;
               break;
              }                                      
          }
  
         for(int i= zz4_shift ; i<lookback_range; i++)
          {
            double downarrow=zz_high[i]; //up val
            double zero=zz_col[i];
            if(downarrow>0 && zero > 0)
              {
               zigzagdowntime = iTime(_Symbol,timeframe,i);
               zigzagdown = downarrow;
               two_down = i;
               break;
              }
          }
         
         int barshift = iBarShift(_Symbol, timeframe, zigzagdowntime);
         barshift = barshift <= 0 ? 1:barshift; 
         
         ArrayResize(ma_fast_buffer, barshift);
         ArrayResize(ma_slow_buffer, barshift);
         for(int i = 0; i < barshift; i++)
         {
           ma_fast_buffer[i] = iMA(_Symbol, timeframe, ma_fastperiod, 0, ma_method, ma_appliedprice, i);
           ma_slow_buffer[i] = iMA(_Symbol, timeframe, ma_slowperiod, 0, ma_method, ma_appliedprice, i);
         }
         
         if(ma_slow_buffer[barshift - 1] < ma_fast_buffer[barshift - 1] && zigzaguptime >= zigzagdowntime) //for sell
         zigzagup_ = zigzagdown;
         Print("zigzagup_  = ", zigzagup_);
         //---
  
         double sl2 = 0;
         double tp2 = NormalizeDouble(latest_price.bid - ( zigzagup_ > latest_price.bid ? (zigzagup_ - latest_price.bid)*first_trade_exit_ratio : (latest_price.bid - zigzagup_)*first_trade_exit_ratio ), _Digits);
         
         double sl = first_trade_exit ? sl2 : 0;
         double tp = first_trade_exit ? tp2 : fixed_pip_exit ? latest_price.bid - (_Point*(fixed_pips_tp*10)) : 0;
         
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double pips = (sl > latest_price.bid ? sl - latest_price.bid:latest_price.bid - sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE); 
         double PipValue = ((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)*point)/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)); 
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100; //MathFloor() 
         
         
         bool res = false;
         if(pip_range(latest_price.bid, zigzagup_) == true)
         res = OrderSend(_Symbol, OP_SELL, use_inital_lots == true ? inital_lots:Lots, latest_price.bid, 100, sl, tp, "SELL Trade");
         
         if(res) //Request is completed or order placed
         {
            Print("trade close = ",Bars-trade_close_shift,"  cross = ",Bars-bearish_cross_shift,"");
            prev_bearish_cross_shift = bearish_cross_shift;
            high = zigzagup_;
            low = latest_price.bid;
            time_of_trade_open = iTime(_Symbol, timeframe, 0);
            history_start = iTime(_Symbol, timeframe, 0);
            
            int ticket = 0;
            for(int i = OrdersTotal()-1; i >= 0; i--)
            {
              if(OrderSelect(i, SELECT_BY_POS))
              {
                ticket = OrderTicket();
                stat_ticket = ticket;
                if(OrderSymbol() == _Symbol)
                break;
              }
            }
            
            ZonePosition = new ZPClass((high - low)*risk_reward_tp, high - low, mtgl_multiplier, swap, commission, _slippage);
            ZonePosition.OpenPosition(ticket);
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }
  
  if (hasMarketOrder())
  trade_check = true;
  
  
  //+------------------------------------------------------------------+
  //|  closing all positions                                           |
  //+------------------------------------------------------------------+
  
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
     if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) // Select the i-th order in the Trade tab
     {
       if (OrderSymbol() == _Symbol) // Check the symbol of the order
       count = count++;
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
   
}

bool hasPendingOrder() {
   for (int i=0; i < OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS)) {
         if (OrderSymbol() == _Symbol && (OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP)){
            return true;
            break;
         }
      }
   }
   return false;
  }


bool hasMarketOrder() {
   for (int i=0; i < OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS)) {
         if (OrderSymbol() == _Symbol && (OrderType()==OP_SELL || OrderType()==OP_BUY)){
            return true;
            break;
         }
      }
   }
   return false;
}

int marketTicket()
{
  int ticket = 0;
  for(int i = 0; i < OrdersTotal(); i++)
    {
       if(OrderSelect(i, SELECT_BY_POS))
       {
         if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL))
         ticket = OrderTicket();
         break;
       }
    }
    
  return ticket;
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

bool pip_range(double val1, double val2)
{
  bool check= false;
  if((val1 > val2 ? val1 - val2:val2 - val1) <= max_pips*10*_Point)
  check = true;
  
  return check;
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

//try to declare the same variables (which are used in the class) in the ea 
//so that we can control them and have the same values as that of those variables in the class.
//make the variables static so that their values won't get reset after an input change, timeframe shift or
//chart change 

//find a way to store values in static global variables. these values will be derived from class variables. 
//they will be used to remember the values which the class variables had before they got re-initialized
