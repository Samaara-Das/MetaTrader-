//+------------------------------------------------------------------+
//|                                          frctl_breakout_mtgl.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"
#resource "\\Indicators\\Examples\\ZigZag.ex5"
#resource "\\Indicators\\x-bars_fractals.ex5"

#include <ZonePosition.mqh>
#include <Trade/trade.mqh>

//EA Description : for a buy, it checks if the the latest fractal high came before latest fractal low and if it broke that high. 
//for a sell, -it checks if the the latest fractal low came before latest fractal high and if it broke that low. mtgl 1 has been added to this
//fractals are also used for calculation of tp and sl

//this ea only allows the first trade to happen if there are no other trades running because they sai dthat only 1 martingale set shud run and no other 
//trade shud happen

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql5.mqh, you must compile this ea also

// fractal parameters
input string frctl_param = " "; //Fill Fractal Parameters
input int      InpLeftSide = 3;          // Number of bars from the left of fractal
input int      InpRightSide = 3;         // Number of bars from the right of fractal
input int fr_shift = 1; //Shift To start looking for fractal high/low
input int lookback = 100; //LookBack Range for finding fractal highs/lows
double fr_col[], fr_low[], fr_high[];

//ea parameters
input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input double inital_lots = 0.01; //Initial Lots
double max_pips = 10; //Min Gap Between S1 & R1 (In Pips)

input string blank2 = " "; // -

input bool risk_reward_exit = true; //Risk Reward Exit
input bool target_tp_exit = false; //tp Target Exit (false for first trade exit ratio)
input bool first_trade_exit = false; //First Trade Exit 
input bool breakeven_exit = false; //Breakeven Exit
input bool fixed_pip_exit = false; //Fixed pip Exit 
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute (for mtgl1)

input string blank3 = " "; // -

input double first_trade_exit_ratio = 1; //First Trade Exit Ratio
input double risk_reward_tp = 2; //TakeProfit Ratio
input double risk_reward_sl = 3; //StopLoss Ratio
input double mtgl_multiplier = 2; //Martingale Multiplier
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input int start_time = 3; //Start Time of EA
input int end_time = 23; //End Time of EA

ENUM_TIMEFRAMES lower_timeframe = PERIOD_CURRENT;

int counter = 0;
int hour;
ulong stat_ticket;
datetime prev_bullish_shift, prev_bearish_shift, bearish_shift, bullish_shift, trade_close_shift;
bool trade_check = false;
double high, low;
long time_of_trade_open;
datetime history_start = iTime(_Symbol, PERIOD_CURRENT, 0), bar1 = 0, bar2 = 0;

CZonePosition *ZonePosition;
CTrade Trade;

int OnInit(void)
{
   ZonePosition = new CZonePosition(0.0, 0.0, mtgl_multiplier, close_trades, target_tp_exit, true, false);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   delete ZonePosition;
}

void OnTick()
{
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  MqlDateTime date;
  TimeCurrent(date);
  
  SymbolInfoTick(_Symbol, latest_price);
  
  int fr_handle = iCustom(_Symbol, PERIOD_CURRENT, "\\Indicators\\x-bars_fractals.ex5", InpLeftSide, InpRightSide);
  
  double fr_dwn=0;
   double fr_up=0;
   datetime fr_uptime=NULL;
   datetime fr_dwntime = NULL;
   
   
   CopyBuffer(fr_handle, 0, fr_shift, lookback, fr_high);
   CopyBuffer(fr_handle, 1, fr_shift, lookback, fr_low);
   ArraySetAsSeries(fr_high, true);
   ArraySetAsSeries(fr_low, true); 

  for(int i= 0 ; i<lookback; i++)
     {
      double downarrow=fr_high[i]; //up val
      if(downarrow>0 )
        {
         fr_uptime = iTime(_Symbol,PERIOD_CURRENT,i+1);
         fr_up = downarrow;
         break;
        }
     }

  for(int i= 0 ; i<lookback; i++)
     {
      double downarrow=fr_low[i]; //up val
      if(downarrow>0 )
        {
         fr_dwntime = iTime(_Symbol,PERIOD_CURRENT,i+1);
         fr_dwn = downarrow;
         break;
        }
     }
  

  if (trade_check == true && PositionSelect(_Symbol) == false)
  {
  trade_check = false;
  long latest_close = 0;
   if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       ulong ticket = HistoryDealGetTicket(HistoryDealsTotal()-1);
       if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY)
       {
       latest_close = HistoryDealGetInteger(ticket, DEAL_TIME);
       }
     }
  trade_close_shift = iTime(_Symbol, PERIOD_CURRENT,0);
  }
  
  if(PositionSelect(_Symbol))
  ZonePosition.OnTick();
  
  //+------------------------------------------------------------------+
  //|   buy condition                                                  |
  //+------------------------------------------------------------------+
 
  bool cond1 = false;
 
  int lowest_ind = iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW, iBarShift(_Symbol,PERIOD_CURRENT,fr_dwntime), 1);
  double lowest = iLow(_Symbol,PERIOD_CURRENT,lowest_ind);
  if( fr_uptime <= fr_dwntime && lowest == fr_dwn && iHigh(_Symbol,PERIOD_CURRENT,0) >= fr_up && fr_uptime >= trade_close_shift && iLow(_Symbol,PERIOD_CURRENT,0) <= fr_up )
  {
  bullish_shift = fr_uptime;
  cond1 = true;
  }
  
  //Print("cond1 = ",fr_uptime <= fr_dwntime,"  cond2 = ",lowest == fr_dwn,"  cond3 = ",iHigh(_Symbol,PERIOD_CURRENT,0) >= fr_up,"  cond4 = ",date3.hour >= start_time,"  cond5 = ",fr_uptime >= trade_close_shift,"");
  //Print("lowest index = ",lowest_ind,"  fr_dwn = ",fr_dwntime,"");
  
  //+------------------------------------------------------------------+
  //|   sell condition                                                 |
  //+------------------------------------------------------------------+
  
  bool cond2 = false;
  
  int highest_ind = iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH, iBarShift(_Symbol,PERIOD_CURRENT,fr_uptime), 1);
  double highest = iHigh(_Symbol,PERIOD_CURRENT,highest_ind);
  if( fr_uptime >= fr_dwntime && highest == fr_up && iLow(_Symbol,PERIOD_CURRENT,0) <= fr_dwn && fr_dwntime >= trade_close_shift && iHigh(_Symbol,PERIOD_CURRENT,0) >= fr_dwn)
  {
  bearish_shift = fr_dwntime;
  cond2 = true;
  }
 
  //Print("cond1 = ",fr_uptime >= fr_dwntime,"  cond2 = ",highest == fr_up,"  cond3 = ",iLow(_Symbol,PERIOD_CURRENT,0) <= fr_dwn,"  cond4 = ",date3.hour >= start_time,"  cond5 = ",fr_dwntime >= trade_close_shift,"");

  //+------------------------------------------------------------------+
  //|   opening trades                                                 |
  //+------------------------------------------------------------------+
  if (cond2 && PositionsTotal() == 0 && date.hour >= start_time && date.hour < end_time)
  {
   
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.bid;
         double sl1 = NormalizeDouble(mrequest.price + ( mrequest.price > fr_up ? ((mrequest.price - fr_up) * risk_reward_sl) : ((fr_up - mrequest.price) * risk_reward_sl) ), _Digits);
         double sl2 = 0;
         double tp1 = NormalizeDouble(mrequest.price - ( mrequest.price > fr_up ? ((mrequest.price - fr_up) * risk_reward_tp) : ((fr_up - mrequest.price) * risk_reward_tp) ), _Digits);
         double tp2 = NormalizeDouble(mrequest.price - ( mrequest.price > fr_up ? ((mrequest.price - fr_up)*first_trade_exit_ratio) : ((fr_up - mrequest.price)*first_trade_exit_ratio) ), _Digits);
        
         mrequest.sl = first_trade_exit ? sl2 : fixed_pip_exit ? mrequest.price + (_Point*(fixed_pips_sl*10)) : risk_reward_exit ? sl1 : 0;
         mrequest.tp = first_trade_exit ? tp2 : fixed_pip_exit ? mrequest.price - (_Point*(fixed_pips_tp*10)) : risk_reward_exit ? tp1 : 0;
         
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //_Bid
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); //_Point
         double pips = (mrequest.sl > mrequest.price ? mrequest.sl - mrequest.price:mrequest.price - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE); //double  AccountFreeMargin();
         double PipValue = ((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)*point)/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)); //MarketInfo(_Symbol, MODE_TICKVALUE)
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100; //MathFloor()
         
         Lots = use_inital_lots == true ? inital_lots:Lots; 
         
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                            
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
            Print("trade close shift = ",trade_close_shift,"    low = ",mrequest.price,"  fr up time = ",fr_uptime," fr dwn time=",fr_dwntime,"  first trade tp ratio1 = ",(fr_up - mrequest.price),"  first trade tp ratio ext = ",((fr_up - mrequest.price)*first_trade_exit_ratio),"");
            Alert("sell taken at ",TimeCurrent()," in ",_Symbol,"");
            prev_bearish_shift = bearish_shift;
            trade_check = true;
            time_of_trade_open = iTime(_Symbol, PERIOD_CURRENT, 0);
            history_start = iTime(_Symbol, PERIOD_CURRENT, 0);
            high = fr_up;
            low = mrequest.price;
   
            ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new CZonePosition((high - low)*risk_reward_tp, high - low, mtgl_multiplier, close_trades, target_tp_exit, true, false);
            ZonePosition.OpenPosition(ticket);
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }
  

  if (cond1 && PositionsTotal() == 0 && date.hour >= start_time && date.hour < end_time )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.ask;
         
         double sl1 = NormalizeDouble(mrequest.price - ( mrequest.price > fr_dwn ? ((mrequest.price - fr_dwn) * risk_reward_sl) : ((fr_dwn - mrequest.price) * risk_reward_sl) ), _Digits);
         double sl2 = 0;
         double tp1 = NormalizeDouble(mrequest.price + ( mrequest.price > fr_dwn ? ((mrequest.price - fr_dwn) * risk_reward_tp) : ((fr_dwn - mrequest.price) * risk_reward_tp) ), _Digits);
         double tp2 = NormalizeDouble(mrequest.price + ( mrequest.price > fr_dwn ? ((mrequest.price - fr_dwn)*first_trade_exit_ratio) : ((fr_dwn - mrequest.price)*first_trade_exit_ratio) ), _Digits);
         
         mrequest.sl = first_trade_exit ? sl2 : fixed_pip_exit ? mrequest.price - (_Point*(fixed_pips_sl*10)) : risk_reward_exit ? sl1 : 0;
         mrequest.tp = first_trade_exit ? tp2 : fixed_pip_exit ? mrequest.price + (_Point*(fixed_pips_tp*10)) : risk_reward_exit ? tp1 : 0;
         
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double pips = (mrequest.price - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         Lots = use_inital_lots == true ? inital_lots:Lots; 

         mrequest.symbol = _Symbol;                                         
         mrequest.volume = Lots;                                          
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         bool res = OrderSend(mrequest, mresult);
         
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
            Print("trade close shift =",trade_close_shift,"  fr up time = ",fr_uptime," fr dwn time=",fr_dwntime,"");
            Alert("buy taken at ",TimeCurrent()," in ",_Symbol,"");
            low = fr_dwn;
            high = mrequest.price;
            prev_bullish_shift = bullish_shift;
            trade_check = true;
            time_of_trade_open = iTime(_Symbol, PERIOD_CURRENT, 0);
            history_start = iTime(_Symbol, PERIOD_CURRENT, 0);
            
            ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new CZonePosition((high - low)*risk_reward_tp, high - low, mtgl_multiplier, close_trades, target_tp_exit, true, false);
            ZonePosition.OpenPosition(ticket);
         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
 
  }
  
  sltp_mod();
  
  //+------------------------------------------------------------------+
  //|  closing all positions                                           |
  //+------------------------------------------------------------------+
   
   //closing when total profit is 0 only when the breakeven exit is allowed
   int count = 0;  
      for(int i = 0; i < PositionsTotal(); i++)
      { 
        ulong ticket=PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) == _Symbol)
        count++; 
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


bool sltp_mod()
{
bool val = false;

      int count = 0, pos = -1;  
      for(int i = 0; i < PositionsTotal(); i++)
      { 
        ulong ticket=PositionGetTicket(i);
        if(PositionGetString(POSITION_SYMBOL) == _Symbol)
        count++; 
        
        if(ticket == stat_ticket) 
        pos = i;
      } 
      
      if(count >= 2)
      {
         ulong ticket = PositionGetTicket(pos);
         
         if(!(PositionGetDouble(POSITION_SL) == 0) || !(PositionGetDouble(POSITION_TP) == 0))
         {
            MqlTradeRequest request;
            MqlTradeResult result;
            ZeroMemory(request);
            ZeroMemory(result);
         
            request.action = TRADE_ACTION_SLTP; 
            request.position = stat_ticket;   
            request.symbol = PositionGetString(POSITION_SYMBOL);    
            request.sl = 0;              
            request.tp = 0;               
            
            bool res = OrderSend(request, result);
            val = res;
         }
      }

return val;
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
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;

    for(int i = PositionsTotal()-1; i >= 0; i--)
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

