//+------------------------------------------------------------------+
//|                                                zz12 ema mtgl.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"
#property copyright "sammy"
#property link      "https://www.mql5.com"
#property version   "13.00"

//EA Description: this takes a buy when price goes from below ema to above ema and while that is happening there has to be a zz leg which is the start of a 1-2 break pattern.
//so the price has to close above the ema in the first leg of the zz 1-2 pattern and then take a buy. for a sell, there has to be zz 1-2 break to the downside and in the first leg
//price has to cross from above the ema to below the ema.
//this has mtgl 1 and mtgl 2
//added zz4_shift for zz based sl so that, it will start looking for highs/lows before shift 1

#resource "\\Indicators\\Examples\\ZigZag.ex5"


//parameters for ema
input string ma_param = " ";  //Fill Moving Average Parameters Below
input int maperiod = 144; //Slow Moving Average Period
input ENUM_MA_METHOD mamethod = MODE_EMA; //MA Method
input ENUM_APPLIED_PRICE appliedprice = PRICE_CLOSE; //Applied MA Price

input string ___ = " "; //   _

input int zz_arrow_depth4 = 3; //Fourth Depth for Zigzag 1-2 entry
input int zz_arrow_deviation4 = 2; //Fourth Deviation for Zigzag 1-2 entry
input int zz_arrow_backStep4 = 2; //Fourth Backstep for Zigzag 1-2 entry
input int zz4_shift = 1; //Fourth ZigZag Shift (shift to start looking for zz highs/lows)

input string _____ = " "; //  " "

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool martingale_exit1 = false; //Martingale Exit 1
input bool martingale_exit2 = false; //Martingale Exit 2
input double mtgl_risk_reward_sl = 3; //mtgl sl
input double mtgl_risk_reward_tp = 2; //mtgl tp
input double mtgl_multiplier = 2; //Martingale Multiplier
input bool first_trade_exit = false; //First Trade Exit
input bool fixed_tp = false; // Fixed Takeprofit
input bool fixed_sl = false; // Fixed StopLoss
input double fixed_tp_pips = 10; //Fixed Takeprofit pips
input double fixed_sl_pips = 50; //Fixed Stoploss pips
input bool zz_swing = false; // ZigZag Swing high/low Based StopLoss
input bool zz_first = false; // First ZZ High/Low Based Stoploss
input bool risk_reward = false; //Risk Reward Based TP
input double risk_reward_tp = 2; //Risk to Reward Ratio for TP

input string tg = " "; // _

input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute
input bool sl_breakeven = false; //Move Sl to Breakeven Price 
input double breakeven_ratio = 1; // Breakeven Ratio
input double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price 

input string blank1 = " "; //_

input bool use_inital_lots = true; //Use Initial Lots
input double Risk = 0.01; // Free margin percentage to risk for the trade
input double inital_lots = 0.01; //Initial Lots
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int start = 4; //Start Time
input int end = 23; //End Time

//handles & indicator buffer arrays
int bb_handle, bb_handle2, mahandle, mafasthandle, div_handle; 
int rsi_handle, std_handle, hkn_ashi_handle;
double maslow[], ma[], bb_upper[], bb_lower[], rsi_val[], rsi_val2[];
double bb_lower2[], bb_upper2[], std_val[], std_val2[], hkn_ashi_val[];
double hkn_ashi_close[], hkn_ashi_low[], hkn_ashi_high[];

ENUM_TIMEFRAMES pos_tf = lower_timeframe;
int prev_bb_bar_sell_sig = 0, shift_of_candle_inside2 = 0, zigzag_high_time, prev_bb_bar_sell_sig1 = 0, prev_bb_bar_buy_sig1 = 0;
int zigzag_high_time1 = 0, zigzag_low_time1 = 0, trade_close_shift = 0, counter = 0;
double pos_tp, pos_sl, bb_buy_low, bb_sell_high, zigzag_low = 0.0, zigzag_high = 0.0;
int time_of_trade_buy = 0, time_of_trade_sell = 0, time_of_trade_open_buy = 0, time_of_trade_open_sell = 0, zigzag_low_time, bb_bar_sell_sig = 0;
int prev_bar_of_candle_buy = 0, prev_bar_of_candle_sell = 0, prev_trade_signal_bar = 0, prev_trade_signal_bar2 = 0, bb_bar_buy_sig = 0, bb_bar_buy_sig_check = 0;
bool trade_check = false, trade_check2 = false, bb_buy_std, bb_buy_rsi, bb_sell_std, bb_sell_rsi;
int regular_buy_div_time = 0, regular_sell_div_time = 0, sell_signal, buy_signal, prev_bb_bar_buy_sig = 0, shift_of_candle_inside = 0, bb_bar_sell_sig_check = 0;
double high, low, zigzagup_, zigzagdown_;
datetime history_start = TimeCurrent(), time_of_trade_open_sell_time, time_of_trade_open_buy_time;

void OnDeinit(const int reason)
{

     IndicatorRelease(bb_handle);
     IndicatorRelease(bb_handle2);
     IndicatorRelease(mafasthandle);
     IndicatorRelease(rsi_handle);
     IndicatorRelease(std_handle);
     IndicatorRelease(hkn_ashi_handle);
     
}
  

void OnTick()
{

  mahandle = iMA(_Symbol, lower_timeframe, maperiod, 0, mamethod, appliedprice);
 
  MqlTick latest_price;
  MqlTradeRequest mrequest;
  MqlTradeResult mresult;
  ZeroMemory(mrequest);
  ZeroMemory(mresult);
  MqlDateTime date;
  MqlDateTime date2;
  TimeCurrent(date);
  SymbolInfoTick(_Symbol, latest_price);
  
  
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
   
 
    
  int zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
  double zz_high2[], zz_low2[], zz_col2[];
  CopyBuffer(zz_handle2, 1, 0, 301, zz_high2);
  CopyBuffer(zz_handle2, 2, 0, 301, zz_low2);
  CopyBuffer(zz_handle2, 0, 0, 301, zz_col2);
  ArraySetAsSeries(zz_high2, true);
  ArraySetAsSeries(zz_low2, true);
  ArraySetAsSeries(zz_col2, true);
  
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
  trade_close_shift = Bars(_Symbol, lower_timeframe);
  } 
  
   if (trade_check2 == true && PositionSelect(_Symbol) == false)
  {
  trade_check2 = false;
  trade_close_shift = Bars(_Symbol, lower_timeframe);
  }
  
  
  bool cond_1 = false;
  if (  ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2)) && iLow(_Symbol,PERIOD_CURRENT,0) <= zigzagdown ) 
  { 
    int _start = iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
    int _end = iBarShift(_Symbol, lower_timeframe, zigzaguptime2);
    
    CopyBuffer(mahandle, 0, 0, _end+1, ma);
    ArraySetAsSeries(ma, true);
    
    bool check1 = false;
    int shift = -1;
    for(int i = ArraySize(ma)-1; i >= _start; i--)
    {
      if(ma[i] > iLow(_Symbol, lower_timeframe, i))
      {
        check1 = true;
        shift = i;
        break;
      }
    }
    
    
    bool check2 = false;
    if(shift >= 0)
    {
    for(int i = shift; i >= _start; i--)
    { 
      if(ma[i] < iClose(_Symbol, lower_timeframe, i))
      {
        check2 = true;
        break;
      }
    }
    }
    
    if(check1 && check2)
    {
    cond_1 = true;
    Print("low=",iLow(_Symbol,PERIOD_CURRENT,0)," <=  zzdwn=",zigzagdown,"");
    }
   
  }
  
  int curr_sig = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzaguptime2);
 
  if ( cond_1 && PositionSelect(_Symbol) == false && buy_signal != curr_sig && curr_sig >= trade_close_shift )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price - (_Point*(fixed_sl_pips*10)), _Digits) : zz_swing == true ? zigzagup : zz_first == true ? zigzagup2 : first_trade_exit == true ? 0:0; //change sl to lowest val
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
         mrequest.tp = risk_reward ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price + (_Point*(fixed_tp_pips*10)), _Digits) : first_trade_exit ? mrequest.price + (mrequest.price-zigzagup) : 0;
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
           history_start = iTime(_Symbol, lower_timeframe, 0);
           trade_check = true;
           buy_signal = curr_sig;
           
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

  
  
  
  
  bool cond_2 = false;
  if (  ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2)) && iHigh(_Symbol,PERIOD_CURRENT,0) >= zigzagup  ) 
  {
    int _start = iBarShift(_Symbol, lower_timeframe, zigzaguptime2);
    int _end = iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
    
    CopyBuffer(mahandle, 0, 0, _end+1, ma);
    ArraySetAsSeries(ma, true);
    
    bool check1 = false;
    int shift = -1;
    for(int i = ArraySize(ma)-1; i >= _start; i--)
    {
      if(ma[i] < iHigh(_Symbol, lower_timeframe, i))
      {
        check1 = true;
        shift = i;
        break;
      }
    }
    
    
    bool check2 = false;
    if(shift >= 0)
    {
    for(int i = shift; i >= _start; i--)
    { 
      if(ma[i] > iClose(_Symbol, lower_timeframe, i))
      {
        check2 = true;
        break;
      }
    }
    }
    
    if(check1 && check2)
    {
      cond_2 = true;
      Print("high=",iHigh(_Symbol,PERIOD_CURRENT,0)," >= zzup=",zigzagup,"");
    }
   
  }
  
  
  curr_sig = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
  if ( cond_2 && PositionSelect(_Symbol) == false && sell_signal != curr_sig && curr_sig >= trade_close_shift )
  {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
      
         
         double slt = fixed_sl == true ? NormalizeDouble(mrequest.price + (_Point*(fixed_sl_pips*10)), _Digits) : zz_swing == true ? zigzagdown : zz_first == true ? zigzagdown2 : first_trade_exit == true ? 0 : 0;  //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
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
         mrequest.tp = risk_reward ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : fixed_tp == true ? NormalizeDouble(mrequest.price - (_Point*(fixed_tp_pips*10)), _Digits) : first_trade_exit ? mrequest.price - (zigzagdown-mrequest.price) : 0; 
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
           history_start = iTime(_Symbol, lower_timeframe, 0);
           trade_check2 = true;
           sell_signal = Bars(_Symbol, lower_timeframe) - iBarShift(_Symbol, lower_timeframe, zigzagdowntime2);
           
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
     datetime latest_close = 0;
     if(HistorySelect(history_start, TimeCurrent()+60*60*24))
     {
       for(int i = HistoryDealsTotal()-1; i >= 0; i--)
       {
       ulong ticket = HistoryDealGetTicket(i);
       if((HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY) && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
       {
       latest_close = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
       break;
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
    
    if ( type == POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == _Symbol && sl_breakeven )
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

    }
    
    
    if ( type == POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == _Symbol && sl_breakeven )
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
           if(close_trades==true)
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
