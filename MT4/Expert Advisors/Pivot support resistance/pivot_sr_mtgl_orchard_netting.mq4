//+------------------------------------------------------------------+
//|                                              pivot_sr_mtgl 2.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"

#include <ZonePosition.mqh>
#define ZPClass CZonePosition

//EA Description : this ea does not have any indicators in the entry condiitions. support & resistance levels are used for calculating sl and tp. at the break of s1/s2/s3
//levels and if the gap between their respective resistance levels is greater than the minimum gap, it takes a buy.
//at the break of r1/r2/r3 levels and if the gap between their respective support levels is greater than the minimum gap, it takes a sell.
//mtgl range levels are the support and resistance levels which influenced the buy/sell.
//in the first trade, the trade might close unexpectedly becasu eof the target high. it will close by default if the target price is hit. the target price is calculated by
//the "TakeProfit Ratio"

//code added to make the ea continue running in these circumstances and not re-initialise:
//this has been done because if a mtgl is running and the ea re-initializes, all the data stored in variables is lost. so, it won't
//pickup from where it left off and the current mtgl won't continue.

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. 

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql4.mqh file, you must compile this ea also

//IMPORTANT : compile ea before use to get the latest changes made in included mqh files

input string blank1 = " "; // -

//ea parameters
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input double inital_lots = 0.01; //Initial Lots
input double max_pips = 10; //Min Gap Between S1 & R1 (In Pips)
input double swap = 0; //Swap for mtgl in pips
input double commission = 0; //Commission for mtgl in pips
input int _slippage = 0; //slippage for pending orders in pips

input string blank2 = " "; // -

input string note2 = " "; //Tp Target is false for the first trade in this netting ea
input bool risk_reward_exit = true; //Risk Reward Exit
input bool first_trade_exit = false; //First Trade Exit 
input bool breakeven_exit = false; //Breakeven Exit
input bool fixed_pip_exit = false; //Fixed pip Exit 
input int trades_for_breakeven = 2; //Min Trades Needed for Breakeven Exit to Apply
 bool close_trades = false; //Close all trades when trade doesn't execute (for mtgl1)
input string note1 = ""; //the "Close All Trades" input is there by default in this ea

input string blank3 = " "; // -

input double first_trade_exit_ratio = 1; //First Trade Exit Ratio (for first trade only)
input double risk_reward_tp = 2; //TakeProfit Ratio
//risk reward tp can work for both mtgl and first trade but as per the strategy, it is only used for the mtgl
input double mtgl_multiplier = 2; //Martingale Multiplier 
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input int start_time = 3; //Start Time of EA
input int end_time = 23; //End Time of EA
 
ENUM_TIMEFRAMES lower_timeframe = PERIOD_CURRENT;

int counter = 0, prev_bullish_shift, prev_bearish_shift, bearish_shift, bullish_shift;
ulong stat_ticket;
int trade_close_shift, hour;
bool trade_check = false;
double high, low;
long time_of_trade_open;
datetime history_start = iTime(_Symbol, PERIOD_CURRENT, 0), bar1 = 0, bar2 = 0;


ZPClass *ZonePosition;

int OnInit(void)
{

   if(hasMarketOrder()==true)
  {
    Print("restart happened... now re-calculating variables");
    ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, 0.0, 0.0, _slippage);
    int ticket = 0;
    ticket = marketTicket();
    bool res = OrderSelect(ticket, SELECT_BY_TICKET);
    
    ZonePosition.mSymbol = OrderSymbol();
    ZonePosition.mInitialPrice = OrderOpenPrice();
    //mInitialVolume and other variables will be filled with a value below (when selecting ticket of first trade)
    ZonePosition.mMultiplier = mtgl_multiplier;
    ZonePosition.mPrevLots = OrderLots();
    ZonePosition.mMagicNumber = OrderMagicNumber();
    ZonePosition.mTradeComment = OrderComment();
    ZonePosition.mTakeprofit = OrderTakeProfit();
    ZonePosition.mTpModify = false;
   
    //Print("symbol = ",ZonePosition.mSymbol,"  initialprice = ",ZonePosition.mInitialPrice,"  multiplier = ",ZonePosition.mMultiplier,"  prevlots = ",ZonePosition.mPrevLots,"");
    //Print("magicnumber = ",ZonePosition.mMagicNumber,"  tradecomment = ",ZonePosition.mTradeComment,"  tradeopen = ",ZonePosition.mTradeOpen,"  tp= ",ZonePosition.mTakeprofit,"  tpmodify = ",ZonePosition.mTpModify,"");
    
    //calculating the first trade's initial lots
    
    if(OrderLots() != inital_lots) //if this isnt the first trade and there hv been more trades before this
    {
      for(int i = OrdersHistoryTotal()-1; i>=0; i--)
      {
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
        {
          if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL))
          {
            int size = ArraySize(ZonePosition.mTickets);
            ArrayResize(ZonePosition.mTickets, size+1);
            ZonePosition.mTickets[size] = OrderTicket();
            
            if(OrderLots()==inital_lots)
            {
              ZonePosition.mInitialVolume = OrderLots();
              ZonePosition.mTradeOpen = OrderOpenTime();
              //Print("ticket of first trade = ",ZonePosition.mTickets[size],"   this trade was in account history");
              break;
            }
          }
        }
      }
    }
    else
    {
      res = OrderSelect(ticket, SELECT_BY_TICKET);
      ArrayResize(ZonePosition.mTickets, 1);
      ZonePosition.mTickets[0] = OrderTicket();
      ZonePosition.mInitialVolume = OrderLots();
      ZonePosition.mTradeOpen = OrderOpenTime();
      //Print("ticket of first trade = ",ZonePosition.mTickets[0],"   this trade was a current trade");
    }
    
    //------------------------------------------------------------------------------------------------------------
    
    
    for(int i = OrdersTotal()-1; i >= 0; i--) //getting ticket of pending order
    {
       if(OrderSelect(i, SELECT_BY_POS))
       {
         if(OrderSymbol() == Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP))
         {
           ticket = OrderTicket();
           break;
         }
       }
    }
    
    res = OrderSelect(ticket, SELECT_BY_TICKET); //selecting ticket of pending order
    
    int type = OrderType()==OP_BUYSTOP ? OP_BUY : OrderType()==OP_SELLSTOP ? OP_SELL : OrderType()==OP_BUY ? OP_BUY : OrderType()==OP_SELL ? OP_SELL : -1;
    ZonePosition.mDirection = type; //setting direction of mDirection so that when pending order turns into market order, we know what type of pending order to put
    //Print("direction of po = ", ZonePosition.mDirection);
   
    //------------------------------------------------------------------------------------------------------------

    double price1, price2;
      
    ticket = marketTicket();
    res = OrderSelect(ticket, SELECT_BY_TICKET);
    price1 = OrderOpenPrice();
    price2 = OrderStopLoss();
      
    //calculate zonesize and mtarget (and variables related to this) if there were no mtgl trades before this
    if(OrderLots() == inital_lots) 
    {
      ZonePosition.mTarget = (price1 > price2 ? price1 - price2 : price2 - price1) * risk_reward_tp;
      ZonePosition.mZoneSize = price1 > price2 ? price1 - price2 : price2 - price1;
      
      ZonePosition.mZoneHigh = price1 >= price2 ? price1 : price2;
      ZonePosition.mZoneLow = price1 <= price2 ? price1 : price2;
        
      ZonePosition.mTargetHigh = ZonePosition.mZoneHigh + ZonePosition.mTarget;
      ZonePosition.mTargetLow = ZonePosition.mZoneLow - ZonePosition.mTarget;
    }

    if(hasPendingOrder()) //this is not needed
    {
 
      //calculate zonesize and mtarget (and variables related to this) because we have to get the exact open price of the 1st and 2nd trade. (if there have been 1st and 2nd trades)
      int market1_ticket = 0, market2_ticket = 0, inc = -1;
      if(OrderLots() != inital_lots) //were ther more mtgl trades before the current trade
      {
        for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
        {
           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderOpenTime()==ZonePosition.mTradeOpen) //getting the current mtgl set's first trade's ticket
             {
               market1_ticket = OrderTicket();
               inc = i;
               break;
             }
           }
        }
        
        for(int i = inc+1; i>=0; i++)
        {
           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderOpenTime()>ZonePosition.mTradeOpen) //if we reach the second order after the first one
             {
               market2_ticket = OrderTicket();
               break;
             }
           }
        }
        
        res = OrderSelect(market1_ticket, SELECT_BY_TICKET,MODE_HISTORY);
        price1 = OrderOpenPrice();
        
        res = OrderSelect(market2_ticket, SELECT_BY_TICKET,MODE_HISTORY);
        price2 = OrderOpenPrice();
        
        Print("price1 = ",price1,"  price2 = ",price2,"  prices of first 2 mtgl trades in account history");
        
        ZonePosition.mZoneHigh = price1 >= price2 ? price1 : price2;
        ZonePosition.mZoneLow = price1 <= price2 ? price1 : price2;
        ZonePosition.mZoneSize = ZonePosition.mZoneHigh - ZonePosition.mZoneLow;
        
        ZonePosition.mTarget = ZonePosition.mZoneSize * risk_reward_tp;
        ZonePosition.mTargetHigh = ZonePosition.mZoneHigh + ZonePosition.mTarget;
        ZonePosition.mTargetLow = ZonePosition.mZoneLow - ZonePosition.mTarget;
      }
      
    }
    else //there will be no need for this, it doesnt matter if there is a pending order or not since we are going to get data from history
    {
    
      //look back in account history to check for trades of type OP_BUY or OP_SELL of the current symbol 
      //get their openprices and subtract them to get mZoneSize. with that value do calculations of target etc
      //those trades must come after mTRadeOpen
      int market1_ticket = 0, market2_ticket = 0, inc = -1;
      datetime prev_openprice;
      for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
        {
           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderOpenTime()==ZonePosition.mTradeOpen) //getting the current mtgl set's first trade's ticket
             {
               market1_ticket = OrderTicket();
               inc = i;
               break;
             }
           }
        }
        
        Print("ticket1 = ",market1_ticket,"  ");
        //Print("inc = ",inc,"  historytotal = ",OrdersHistoryTotal()-1);
        for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
        {
           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
             //write condition which checks if current trade's opentime is greater than mTradeOpen but less than the varaible which stores the lesser value
                                                                       
           
             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderOpenTime()==ZonePosition.mTradeOpen) //if we get to the first trade, break the loop
             {
               Print("ticket2 = ",market2_ticket,"  in looop");
               break;
             }
             
             if(OrderSymbol() == _Symbol && (OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderOpenTime()>ZonePosition.mTradeOpen) //if we reach the second order before the first one
             {
               market2_ticket = OrderTicket();
               //Print("ticket2 = ",market2_ticket,"  in looop");
             }
           }
        }
        //Print("ticket1 = ",market1_ticket,"  ticket2 = ",market2_ticket,"");
        
        res = OrderSelect(market1_ticket, SELECT_BY_TICKET,MODE_HISTORY);
        double price1 = OrderOpenPrice();
        
        res = OrderSelect(market2_ticket, SELECT_BY_TICKET,MODE_HISTORY);
        double price2 = OrderOpenPrice();
        
        Print("price1 = ",price1,"  price2 = ",price2,"  prices of first 2 mtgl trades in account history");
        
        ZonePosition.mZoneHigh = price1 >= price2 ? price1 : price2;
        ZonePosition.mZoneLow = price1 <= price2 ? price1 : price2;
        ZonePosition.mZoneSize = ZonePosition.mZoneHigh - ZonePosition.mZoneLow;
        
        ZonePosition.mTarget = ZonePosition.mZoneSize * risk_reward_tp;
        ZonePosition.mTargetHigh = ZonePosition.mZoneHigh + ZonePosition.mTarget;
        ZonePosition.mTargetLow = ZonePosition.mZoneLow - ZonePosition.mTarget;
        
      
      //if the above also doesnt work, just resort to the code below
      //try to figure out a way where we can store the variables "high" and "low" in the comment of the first trade
    
      ZonePosition.mTarget = 0;
      ZonePosition.mZoneSize = 0;
    }
    
    //------------------------------------------------------------------------------------------------------------
    
    ticket = marketTicket();
    res = OrderSelect(ticket, SELECT_BY_TICKET);
    
    //also calculate estimated loss for current open trade
    int size = ArraySize(ZonePosition.volProfit);
    ArrayResize(ZonePosition.volProfit, size+1);
              
    if(OrderType() == OP_SELL)
    ZonePosition.volProfit[size] = ZonePosition.mPrevLots*(OrderOpenPrice() - ZonePosition.mZoneHigh);
        
    if(OrderType() == OP_BUY)
    ZonePosition.volProfit[size] = ZonePosition.mPrevLots*(ZonePosition.mZoneLow - OrderOpenPrice());
    
    if(OrderLots() != inital_lots) //have there been previous mtgl trades before current running order
    {
      for(int i = OrdersHistoryTotal()-1; i >= 0; i--) //calculating booked loss of closed trades
        { 
           if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) 
           {
            if(OrderLots()==inital_lots) //if we reach the first trade, no need to move on further to calculate losses for previous trades
            {
              //calculate mVolProfit
              size = ArraySize(ZonePosition.volProfit);
              ArrayResize(ZonePosition.volProfit, size+1);
              ZonePosition.volProfit[size] = OrderType()==OP_BUY ? OrderLots()* (OrderClosePrice()-OrderOpenPrice()) : OrderType()==OP_SELL ? OrderLots()* (OrderOpenPrice()-OrderClosePrice()) : 0;
              break;
            }
           
            if(OrderSymbol()==ZonePosition.mSymbol && (OrderType()==OP_BUY || OrderType()==OP_SELL))
            {
              type = OrderType();
              double volume = OrderLots();
              double closeprice = OrderClosePrice();
              double openprice = OrderOpenPrice();
              //calculate mVolProfit
              size = ArraySize(ZonePosition.volProfit);
              ArrayResize(ZonePosition.volProfit, size+1);
              
              if(type == OP_BUY)
              ZonePosition.volProfit[size] = volume * (closeprice-openprice);
          
              if(type == OP_SELL)
              ZonePosition.volProfit[size] = volume * (openprice-closeprice);
              break;
            }
           } 
        }
    }
    
    //------------------------------------------------------------------------------------------------------------
    
    ZonePosition.mSlippage = _slippage;
    ZonePosition.mSupplement = ((swap*10) * _Point) + ((commission*10) * _Point);
    ZonePosition.mStatus = ZONE_POSITION_STATUS_OPEN;
    
    
  }

   ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, 0.0, 0.0, _slippage);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete ZonePosition;
}

void OnTick()
{
  MqlTick latest_price;
  MqlDateTime date;
  TimeCurrent(date);
  MqlDateTime date3;
 
  SymbolInfoTick(_Symbol, latest_price);
  
  if (trade_check == true && hasMarketOrder() == false)
  {
  trade_check = false;
  trade_close_shift = Bars;
  }
 
  bool reached = false;
  ZonePosition.OnTick(reached);
  
  double _High = iHigh(_Symbol, PERIOD_CURRENT, 1);
  double _Low = iLow(_Symbol, PERIOD_CURRENT, 1);
  double _Close = iClose(_Symbol, PERIOD_CURRENT, 1);
  double pivot_level = ((_High+_Close+_Low)/3);
  double s_level=0, r_level=0;
  double s_level1=0, r_level1=0;
  double s_level2=0, r_level2=0;
  double s_level3=0, r_level3=0;
 
  s_level1 = ((2 * pivot_level) - _High);
  r_level1 = ((2 * pivot_level) - _Low);

  s_level2 =  (pivot_level - (_High-_Low));
  r_level2 = (pivot_level + (_High-_Low));

  r_level3 = ( _High + (2*(pivot_level-_Low)) );
  s_level3 = ( _Low - (2*(_High-pivot_level)) ); 

  ObjectDelete(0, "s_level1");
  HLineCreate(0, "s_level1", 0, s_level1, clrRed, STYLE_SOLID);
  
  ObjectDelete(0, "r_level1");
  HLineCreate(0, "r_level1", 0, r_level1, clrLawnGreen, STYLE_SOLID);
  
  //support & resistance level 2
  ObjectDelete(0, "s_level2");
  HLineCreate(0, "s_level2", 0, s_level2, clrRed, STYLE_SOLID);
  
  ObjectDelete(0, "r_level2");
  HLineCreate(0, "r_level2", 0, r_level2, clrLawnGreen, STYLE_SOLID);
  
  //support & resistance level 3
  ObjectDelete(0, "s_level3");
  HLineCreate(0, "s_level3", 0, s_level3, clrRed, STYLE_SOLID);
  
  ObjectDelete(0, "r_level3");
  HLineCreate(0, "r_level3", 0, r_level3, clrLawnGreen, STYLE_SOLID);
  
  //Print("support = ",s_level,"  resistance = ",r_level,"");

  //+------------------------------------------------------------------+
  //|   buy condition                                                  |
  //+------------------------------------------------------------------+
 
  bool cond1 = false;
  TimeToStruct(iTime(_Symbol, PERIOD_CURRENT, 1), date3);
 
  double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  
  bool check1 = ask >= r_level1;
  bool check2 = ask >= r_level2;
  bool check3 = ask >= r_level3;

  s_level = check1 ? s_level1 : check2 ? s_level2 : check3 ? s_level3 : 0;
  r_level = check1 ? r_level1 : check2 ? r_level2 : check3 ? r_level3 : 0;
  
  bool pip_check = check1 && pip_range(r_level1, s_level1) ? true : check2 && pip_range(r_level2, s_level2) ? true : check3 && pip_range(r_level3, s_level3) ? true : false;
  ///Print("1 = ",ask >= r_level1,"  2 = ", ask >= r_level2,"  3 = ", ask >= r_level3,"     ask=",ask," r1 =",r_level1," r2 =",r_level2," r3 =",r_level3,"");
  //Print("rang1 = ",pip_range(r_level1, s_level1),"  range2 = ",pip_range(r_level2, s_level2),"  rang3 = ",pip_range(r_level3, s_level3),"");
  //Print(" for buy  level1 = ",check1 && pip_range(r_level1, s_level1),"  level2 = ",check2 && pip_range(r_level2, s_level2),"  level3 = ",check3 && pip_range(r_level3, s_level3),"");
//Print("r_level = ", r_level);
  //Print("",pip_range(r_level1, s_level1),"  ",pip_range(r_level2, s_level2),"  ",pip_range(r_level3, s_level3),"");

  if(pip_check /*High >= r_level*/ && Bars-1 >= trade_close_shift && prev_bullish_shift < Bars-1 && date3.hour >= start_time)
  {
  bullish_shift = Bars - 1;
  s_level = check1 ? s_level1 : check2 ? s_level2 : check3 ? s_level3 : 0;
  r_level = check1 ? r_level1 : check2 ? r_level2 : check3 ? r_level3 : 0;
  cond1 = true;
  }
  
  //Print("cond1 = ",ask >= r_level,"  cond2 = ",Bars(_Symbol,PERIOD_CURRENT)-1 >= trade_close_shift,"  cond3 = ",prev_bullish_shift < Bars(_Symbol,PERIOD_CURRENT)-1,"  cond4 = ",date3.hour >= start_time,"");
  
  //+------------------------------------------------------------------+
  //|   sell condition                                                 |
  //+------------------------------------------------------------------+
  
  bool cond2 = false;
  TimeToStruct(iTime(_Symbol, PERIOD_CURRENT, 1), date3);
 
  double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

  check1 = bid <= s_level1;
  check2 = bid <= s_level2;
  check3 = bid <= s_level3;
  
  pip_check = check1 && pip_range(r_level1, s_level1) ? true : check2 && pip_range(r_level2, s_level2) ? true : check3 && pip_range(r_level3, s_level3) ? true : false;
  //Print(" for sell  level1 = ",check1 && pip_range(r_level1, s_level1),"  level2 = ",check2 && pip_range(r_level2, s_level2),"  level3 = ",check3 && pip_range(r_level3, s_level3),"");
  
  if(pip_check && Bars-1 >= trade_close_shift && prev_bearish_shift < Bars-1 && date3.hour >= start_time)
  {
  //Print("pip = ", pip_check);
  bearish_shift = Bars- 1;
  s_level = check1 ? s_level1 : check2 ? s_level2 : check3 ? s_level3 : 0;
  r_level = check1 ? r_level1 : check2 ? r_level2 : check3 ? r_level3 : 0;
  cond2 = true;
  }
   
     
  //+------------------------------------------------------------------+
  //|   opening trades                                                 |
  //+------------------------------------------------------------------+
  //Print("",cond2,"   ",hasMarketOrder() == false,"  ",date.hour >= start_time && date.hour < end_time,"");
  if (cond2 && hasMarketOrder() == false && date.hour >= start_time && date.hour < end_time)
  {
   
         double sl2 = 0;
         double tp1 = NormalizeDouble(latest_price.bid - ( latest_price.bid > r_level ? ((latest_price.bid - r_level) * risk_reward_tp) : ((r_level - latest_price.bid) * risk_reward_tp) ), _Digits);
         double tp2 = NormalizeDouble(latest_price.bid - ( latest_price.bid > r_level ? ((latest_price.bid - r_level)*first_trade_exit_ratio) : ((r_level - latest_price.bid)*first_trade_exit_ratio) ), _Digits);
        
         double sl = first_trade_exit ? sl2 : fixed_pip_exit ? latest_price.bid + (_Point*(fixed_pips_sl*10)) : risk_reward_exit ? 0 : 0;
         double tp = first_trade_exit ? tp2 : fixed_pip_exit ? latest_price.bid - (_Point*(fixed_pips_tp*10)) : risk_reward_exit ? tp1 : 0;
         
         bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //_Bid
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); //_Point
         double pips = (sl > latest_price.bid ? sl - latest_price.bid:latest_price.bid - sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE); //double  AccountFreeMargin();
         double PipValue = ((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)*point)/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)); //MarketInfo(_Symbol, MODE_TICKVALUE)
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100; //MathFloor()
         
         bool res = false;
         //if(pip_range(latest_price.bid, zigzagup_) == true)
         res = OrderSend(_Symbol, OP_SELL, use_inital_lots == true ? inital_lots:Lots, latest_price.bid, 100, sl, tp, "SELL Trade");
         
         if(res) //Request is completed or order placed
         {
            high = r_level  /*latest_price.bid + 0.00300*/;
            low = latest_price.bid;
            time_of_trade_open = iTime(_Symbol, PERIOD_CURRENT, 0);
            history_start = iTime(_Symbol, PERIOD_CURRENT, 0);
            
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
  

  //Print("",cond1,"   ",hasMarketOrder() == false,"  ",date.hour >= start_time && date.hour < end_time,"");
  if (cond1 && hasMarketOrder() == false && date.hour >= start_time && date.hour < end_time )
  {
         
         double sl2 = 0;
         double tp1 = NormalizeDouble(latest_price.ask + ( latest_price.ask > s_level ? ((latest_price.ask - s_level) * risk_reward_tp) : ((s_level - latest_price.ask) * risk_reward_tp) ), _Digits);
         double tp2 = NormalizeDouble(latest_price.ask + ( latest_price.ask > s_level ? ((latest_price.ask - s_level)*first_trade_exit_ratio) : ((s_level - latest_price.ask)*first_trade_exit_ratio) ), _Digits);
         
         double sl = first_trade_exit ? sl2 : fixed_pip_exit ? latest_price.ask - (_Point*(fixed_pips_sl*10)) : risk_reward_exit ? 0 : 0;
         double tp = first_trade_exit ? tp2 : fixed_pip_exit ? latest_price.ask + (_Point*(fixed_pips_tp*10)) : risk_reward_exit ? tp1 : 0;
         
         ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double pips = (latest_price.ask - sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         bool res = false;
         //if(pip_range(latest_price.bid, zigzagup_) == true)
         res = OrderSend(_Symbol, OP_BUY, use_inital_lots == true ? inital_lots:Lots, latest_price.bid, 100, sl, tp, "SELL Trade");
         
         if(res) //Request is completed or order placed
         {
            low = s_level /*latest_price.ask - 0.00300*/;
            high = latest_price.ask;
            time_of_trade_open = iTime(_Symbol, PERIOD_CURRENT, 0);
            history_start = iTime(_Symbol, PERIOD_CURRENT, 0);
            
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
   if(breakeven_exit == true && count >= trades_for_breakeven)  
   { 
     if(profit_total(_Symbol) >= 0)
     {
       close_all(_Symbol);
     }
   }
   
}

bool hasPendingOrder() {

   for (int i=OrdersTotal()-1; i >= 0; i--) 
   {
      if(OrderSelect(i,SELECT_BY_POS)) 
      {
         if (OrderSymbol() == _Symbol && (OrderType()==OP_SELLSTOP || OrderType()==OP_BUYSTOP))
         {
           return true;
           break;
         }
      }
   }
   
   return false;
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
  
int marketTicket()
{
  int ticket = 0;
  for(int i = OrdersTotal()-1; i >= 0; i--)
    {
       if(OrderSelect(i, SELECT_BY_POS))
       {
         if(OrderSymbol() == Symbol() && (OrderType()==OP_BUY || OrderType()==OP_SELL))
         {
           ticket = OrderTicket();
           break;
         }
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
  if((val1 > val2 ? val1 - val2:val2 - val1) >= max_pips*10*_Point)
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


bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            hidden=false,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- if the price is not set, set it at the current Bid price level 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a horizontal line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Move horizontal line                                             | 
//+------------------------------------------------------------------+ 
bool HLineMove(const long   chart_ID=0,   // chart's ID 
               const string name="HLine", // line name 
               double       price=0)      // line price 
  { 
//--- if the line price is not set, move it to the current Bid price level 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- move a horizontal line 
   if(!ObjectMove(chart_ID,name,0,0,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to move the horizontal line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 
