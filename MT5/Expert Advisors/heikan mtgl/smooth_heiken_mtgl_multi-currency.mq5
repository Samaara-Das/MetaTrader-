//+------------------------------------------------------------------+
//|                                                  heiken_mtgl.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"
#resource "\\Indicators\\heiken_ashi_smoothed.ex5"
#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <smoothalgorithms.mqh> 

//EA Description : heiken ashi used for buy and sell signals. if candles turns from red to blue or if candles turn from blue to red while there is a candlestick pattern take a buy or sell
//respectfully. this is a multi currency version of smooth_heiken_mtgl
//added a different kind of martingale which increases lotsize if last trade was a loss & resets to initial lotsize if last trade was a profit.

//heiken ashi parameters
input string heiken_param = " "; //Fill Heiken Parameters 
input Smooth_Method MA_SMethod=MODE_JJMA; //Smoothing method
input int SmLength=30; //Smoothing depth                    
input int SmPhase=100; //Smoothing parameter
int heiken_handle; 
double heiken_open[], heiken_close[], heiken_high[], heiken_low[], heiken_color[];

input string blank1 = " "; // " "

//zigzag parameters
input string zz_param = " "; //Fill ZigZag Parameters (for entry of 1st trade)
input int zz_depth = 8; //Depth
input int zz_deviation = 5; //Deviation
input int zz_backstep = 3; //Backstep 
int zz_handle;
double zz_col[], zz_low[], zz_high[];

input string blank2 = " "; // " "

//ea parameters
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input double inital_lots = 0.01; //Initial Lots
input double max_pips = 10; //Max Pips

input string blank3 = " "; // " "

input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
input bool first_trade_exit = false; //First Trade Exit (1:1 risk-reward)
//input bool breakeven_exit = false; //Breakeven Exit
input bool fixed_pip_exit = false; //Fixed pip Exit 
//input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

input string blank4 = " "; // " "

input double risk_reward_tp = 2; //TakeProfit Ratio
input double risk_reward_sl = 3; //StopLoss Ratio
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input int start_time = 3; //Start Time of EA
input int end_time = 23; //End Time of EA
input string user_symbols = "GBPUSD,GBPJPY"; //Symbols for EA

ENUM_TIMEFRAMES lower_timeframe = PERIOD_CURRENT;


void OnDeinit(const int reason)
{
  IndicatorRelease(heiken_handle);
  IndicatorRelease(zz_handle);
}

int bullish_shift[], bearish_shift[], prev_bullish_shift[], prev_bearish_shift[], _Size;
int trade_close_shift[], red_shift[], blue_shift[], red_shift_hr[], blue_shift_hr[], counter[];
bool trade_check[];
double high[], low[];
long time_of_trade_open[];
datetime red_shift_day[], blue_shift_day[];
datetime history_start = TimeCurrent();
string delim = ",", symbols[];


int OnInit()
{
  ushort sdelim = StringGetCharacter(delim, 0);   
  StringSplit(user_symbols, sdelim, symbols);
  _Size = ArraySize(symbols);
  
  ArrayResize(bullish_shift, _Size);ArrayResize(bearish_shift, _Size);ArrayResize(prev_bullish_shift, _Size);ArrayResize(prev_bearish_shift, _Size); 
  ArrayResize(trade_close_shift, _Size);ArrayResize(red_shift, _Size);ArrayResize(blue_shift, _Size);ArrayResize(red_shift_hr, _Size);ArrayResize(blue_shift_hr, _Size);ArrayResize(counter, _Size);
  ArrayResize(trade_check, _Size);
  ArrayResize(high, _Size);ArrayResize(low, _Size);
  ArrayResize(time_of_trade_open, _Size);
  ArrayResize(red_shift_day, _Size);ArrayResize(blue_shift_day, _Size);
  
  return(INIT_SUCCEEDED);
}

void OnTick()
{

  for(int j = 0; j < _Size; j++)
  {
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  MqlDateTime date;
  TimeCurrent(date);
  MqlDateTime date2;
  MqlDateTime date3;
  
  heiken_handle = iCustom(symbols[j], PERIOD_CURRENT, "\\Indicators\\heiken_ashi_smoothed.ex5", MA_SMethod, SmLength, SmPhase);
  zz_handle = iCustom(symbols[j], PERIOD_CURRENT, "\\Indicators\\Examples\\ZigZag.ex5", zz_depth, zz_deviation, zz_backstep);
  
  SymbolInfoTick(symbols[j], latest_price);
  
  CopyBuffer(heiken_handle, 0, 1, 1, heiken_open);
  CopyBuffer(heiken_handle, 1, 1, 1, heiken_high);
  CopyBuffer(heiken_handle, 2, 1, 1, heiken_low);
  CopyBuffer(heiken_handle, 3, 1, 1, heiken_close);
  CopyBuffer(heiken_handle, 4, 1, 2, heiken_color);
  ArraySetAsSeries(heiken_open, true);
  ArraySetAsSeries(heiken_high, true);
  ArraySetAsSeries(heiken_low, true);
  ArraySetAsSeries(heiken_close, true);
  ArraySetAsSeries(heiken_color, true);
  
  if (trade_check[j] == true && PositionSelect(symbols[j]) == false)
  {
  trade_check[j] = false;
  long latest_close = 0;
   if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY)
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
  trade_close_shift[j] = Bars(symbols[j], PERIOD_CURRENT) - iBarShift(symbols[j], PERIOD_CURRENT, latest_close);
  }
  
  //+------------------------------------------------------------------+
  //|   buy condition                                                  |
  //+------------------------------------------------------------------+
  
  if(heiken_color[0] == 1)
  red_shift[j] = Bars(symbols[j], PERIOD_CURRENT) - 1; 
  
  if(heiken_color[0] == 1)
  {
  TimeToStruct(iTime(symbols[j], PERIOD_CURRENT, 1), date2);
  red_shift_hr[j] = date2.hour;
  red_shift_day[j] = date2.day;
  }
  
  bool cond1 = false;
  TimeToStruct(iTime(symbols[j], PERIOD_CURRENT, 1), date3);
 
  if(heiken_color[0] == 0 && heiken_low[0] == heiken_open[0] && red_shift[j] >= trade_close_shift[j] && red_shift_hr[j] >= start_time && red_shift_day[j] == date3.day)
  {
  bullish_shift[j] = Bars(symbols[j], PERIOD_CURRENT) - 1;
  cond1 = true;
  }
  
  //+------------------------------------------------------------------+
  //|   sell condition                                                 |
  //+------------------------------------------------------------------+
  
  if(heiken_color[0] == 0)
  blue_shift[j] = Bars(symbols[j], PERIOD_CURRENT) - 1; 
  
  if(heiken_color[0] == 0)
  {
  TimeToStruct(iTime(symbols[j], PERIOD_CURRENT, 1), date2);
  blue_shift_hr[j] = date2.hour;
  blue_shift_day[j] = date2.day; 
  }
  
  bool cond2 = false;
  TimeToStruct(iTime(symbols[j], PERIOD_CURRENT, 1), date3);
 
  if(heiken_color[0] == 1 && heiken_high[0] == heiken_open[0] && blue_shift[j] >= trade_close_shift[j] && blue_shift_hr[j] >= start_time && blue_shift_day[j] == date3.day)
  {
  bearish_shift[j] = Bars(symbols[j], PERIOD_CURRENT) - 1;
  cond2 = true;
  }
  
  //+------------------------------------------------------------------+
  //|   zigzag highs & lows                                            |
  //+------------------------------------------------------------------+
   
   CopyBuffer(zz_handle, 1, Bars(symbols[j], PERIOD_CURRENT)-bearish_shift[j], 200, zz_high);
   CopyBuffer(zz_handle, 2, Bars(symbols[j], PERIOD_CURRENT)-bearish_shift[j], 200, zz_low);
   CopyBuffer(zz_handle, 0, Bars(symbols[j], PERIOD_CURRENT)-bearish_shift[j], 200, zz_col);
   ArraySetAsSeries(zz_col, true);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true); 
  
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;

  for(int i= 0 ; i<200; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(symbols[j],PERIOD_CURRENT,i);
         zigzagdown = downarrow;
         break;
        }
     }
     
   CopyBuffer(zz_handle, 1, Bars(symbols[j], PERIOD_CURRENT)-bullish_shift[j], 200, zz_high);
   CopyBuffer(zz_handle, 2, Bars(symbols[j], PERIOD_CURRENT)-bullish_shift[j], 200, zz_low);
   CopyBuffer(zz_handle, 0, Bars(symbols[j], PERIOD_CURRENT)-bullish_shift[j], 200, zz_col);
   ArraySetAsSeries(zz_col, true);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true); 
   
  for(int i= 0 ; i<200; i++)
     {
      double uparrow=zz_low[i]; //down val
      double zero=zz_col[i];
      if(uparrow>0 && zero > 0)
        {
         zigzaguptime = iTime(symbols[j],PERIOD_CURRENT,i);
         zigzagup = uparrow;
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
    Print("request sent for buy");
    setorder(POSITION_TYPE_BUY, symbols[j], j);
    //Print("sent buy order  high[j] = ",high[j]," ask = ",SymbolInfoDouble(symbols[j],SYMBOL_ASK),"");
  }
  
  if (  (SymbolInfoDouble(symbols[j],SYMBOL_BID) <= low[j]) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
  {
    Print("request sent for sell");
    setorder(POSITION_TYPE_SELL, symbols[j], j);
    //Print("sent buy order  low[j] = ",low[j],"  bid = ",SymbolInfoDouble(symbols[j],SYMBOL_BID),"");
  }
  }
  
  //+------------------------------------------------------------------+
  //|   opening trades                                                 |
  //+------------------------------------------------------------------+
  
  if (cond1 && PositionSelect(symbols[j]) == false && date.hour >= start_time && date.hour < end_time )
  {
         long digits = SymbolInfoInteger(symbols[j], SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbols[j],SYMBOL_POINT);
         
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.ask;
         
         double sl1 = NormalizeDouble(mrequest.price - ( mrequest.price > zigzagup ? ((mrequest.price - zigzagup) * risk_reward_sl) : ((zigzagup - mrequest.price) * risk_reward_sl) ), digits);
         double sl2 = 0;
         double tp1 = NormalizeDouble(mrequest.price + ( mrequest.price > zigzagup ? ((mrequest.price - zigzagup) * risk_reward_tp) : ((zigzagup - mrequest.price) * risk_reward_tp) ), digits);
         double tp2 = NormalizeDouble(mrequest.price + ( mrequest.price > zigzagup ? (mrequest.price - zigzagup) : (zigzagup - mrequest.price) ), digits);
         
         mrequest.sl = first_trade_exit ? sl2 : fixed_pip_exit ? mrequest.price - (point*(fixed_pips_sl*10)) : sl1;
         mrequest.tp = first_trade_exit ? tp2 : fixed_pip_exit ? mrequest.price + (point*(fixed_pips_tp*10)) : tp1;
         
         double ask = SymbolInfoDouble(symbols[j],SYMBOL_ASK);
         double pips = (mrequest.price - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(symbols[j], SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(symbols[j],SYMBOL_TRADE_TICK_SIZE)));
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
         
         mrequest.symbol = symbols[j];                                         
         mrequest.volume = Lots;                                          
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         if(pip_range(mrequest.price, zigzagup, symbols[j]) == true)
         bool res = OrderSend(mrequest, mresult);
         
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
            Print("start time = ",start_time,"  red shift = ",red_shift_hr[j]," zz low[j] = ",zigzagup,"");
            low[j] = zigzagup;
            high[j] = mrequest.price;
            prev_bullish_shift[j] = bullish_shift[j];
            time_of_trade_open[j] = iTime(symbols[j], PERIOD_CURRENT, 0);
            trade_check[j] = true;
            counter[j]++;
            
            if (  (SymbolInfoDouble(symbols[j],SYMBOL_BID) <= low[j]) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY  )
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
  
  if (cond2 && PositionSelect(symbols[j]) == false && date.hour >= start_time && date.hour < end_time)
  {
         long digits = SymbolInfoInteger(symbols[j], SYMBOL_DIGITS);
         double point = SymbolInfoDouble(symbols[j],SYMBOL_POINT);
         
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.bid;
         double sl1 = NormalizeDouble(mrequest.price + ( mrequest.price > zigzagdown ? ((mrequest.price - zigzagdown) * risk_reward_sl) : ((zigzagdown - mrequest.price) * risk_reward_sl) ), digits);
         double sl2 = 0;
         double tp1 = NormalizeDouble(mrequest.price - ( mrequest.price > zigzagdown ? ((mrequest.price - zigzagdown) * risk_reward_tp) : ((zigzagdown - mrequest.price) * risk_reward_tp) ), digits);
         double tp2 = NormalizeDouble(mrequest.price - ( mrequest.price > zigzagdown ? (mrequest.price - zigzagdown) : (zigzagdown - mrequest.price) ), digits);
        
         mrequest.sl = first_trade_exit ? sl2 : fixed_pip_exit ? mrequest.price + (point*(fixed_pips_sl*10)) : sl1;
         mrequest.tp = first_trade_exit ? tp2 : fixed_pip_exit ? mrequest.price - (point*(fixed_pips_tp*10)) : tp1;
         
         double bid = SymbolInfoDouble(symbols[j],SYMBOL_BID); //_Bid
         double pips = (mrequest.sl > mrequest.price ? mrequest.sl - mrequest.price:mrequest.price - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE); //double  AccountFreeMargin();
         double PipValue = ((SymbolInfoDouble(symbols[j], SYMBOL_TRADE_TICK_VALUE)*point)/SymbolInfoDouble(symbols[j],SYMBOL_TRADE_TICK_SIZE)); //MarketInfo(symbols[j], MODE_TICKVALUE)
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100; //MathFloor()
         
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
         
         mrequest.symbol = symbols[j];                                         
         mrequest.volume = Lots;                                            
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         if(pip_range(mrequest.price, zigzagdown, symbols[j]) == true)
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
            Print("trade close shift = ",Bars(symbols[j],PERIOD_CURRENT)-trade_close_shift[j],"  blue shift = ",Bars(symbols[j],PERIOD_CURRENT)-blue_shift[j],"   tarde close shift = ",trade_close_shift[j],"  blue shift = ",blue_shift[j],"");
            prev_bearish_shift[j] = bearish_shift[j];
            time_of_trade_open[j] = iTime(symbols[j], PERIOD_CURRENT, 0);
            low[j] = mrequest.price;
            high[j] = zigzagdown;
            trade_check[j] = true;
            counter[j]++;
            
            if (  (SymbolInfoDouble(symbols[j],SYMBOL_ASK) >= high[j]) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL  )
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
  
  
  //+------------------------------------------------------------------+
  //|  closing all positions                                           |
  //+------------------------------------------------------------------+
  
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
     
     if(latest_close > time_of_trade_open[j]) //check if most recent close time is greater than time_of_open_trade2, if so then close all open orders
     {
       close_all(symbols[j], j);
     }

   }
   
   //closing when total profit is 0 only when the breakeven exit is allowed
   /*if(breakeven_exit == true && PositionsTotal() >= trades_for_breakeven) //this is not coded correctly yet for this multi currency ea
   { 
     if(profit_total() >= 0)
     {
       close_all();
     }
   }*/
   
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
         sl = PositionGetDouble(POSITION_PRICE_OPEN)-NormalizeDouble((range*risk_reward_sl), digits);
         tp = PositionGetDouble(POSITION_PRICE_OPEN)+NormalizeDouble((range*risk_reward_tp), digits);  
         }                                                                                
         else
         {
         sl = PositionGetDouble(POSITION_PRICE_OPEN)+NormalizeDouble((range*risk_reward_sl), digits);   
         tp = PositionGetDouble(POSITION_PRICE_OPEN)-NormalizeDouble((range*risk_reward_tp), digits); 
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

bool pip_range(double val1, double val2, string symb)
{
  bool check= false;
  if((val1 > val2 ? val1 - val2:val2 - val1) <= max_pips*10*SymbolInfoDouble(symb, SYMBOL_POINT))
  check = true;
  
  return check;
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
