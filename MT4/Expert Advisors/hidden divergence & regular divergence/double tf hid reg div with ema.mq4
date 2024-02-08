//+------------------------------------------------------------------+
//|   doube_rsi_hidden_regular_divergence_with_ema_multi-deg_div.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"
#include <multidiv.mqh>

#include <ZonePosition.mqh>
#define ZPClass CZonePosition

//EA LOGIC DESCRIPTION : rsi hidden divergence and 200 ema (optional) on htf for trend bias. 
//rsi regular divergence on ltf, below/above 200 ema( optional) and heiken ashi candle for entry;
//waverunner low/high, reg div 2nd high/low and fixed pips are used for sl
//RR tp and fixed for tp.
//uses multi degree divergence's && takes the latets one for the entry

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. 
//netting will start based on wherever the sl level is for the first trade. 
//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql4.mqh file, you must compile this ea also

//IMPORTANT : compile ea before use to get the latest changes made in included mqh files

input string ____ = " "; //  

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
input int fonts = 13; //Font Size of Label
input color bear_color = clrRed; //Colour of Bearish Div
input color bull_color = clrLime; //Colour of Bullish Div
input int div_lookback = 100; //Lookback for Divergence

input string c3 = " "; // _
input string __ = " "; // _

//param for ma
input string ma_param = " "; //EMA Parameters
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //EMA Applied Price
input ENUM_MA_METHOD ma_methodd = MODE_EMA; //EMA Method
input int ma_periodd = 200; //EMA Period

input string d4 = " "; // _
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
input string sl_param = " "; //Fill StopLoss & TakeProfit Inputs
input double pips_for_sl = 0; //Amount of pips to be added/subtracted from stoploss
input string f6 = ""; //_
input bool zigzag_sl = false; //Allow ZigZag based stoploss
input bool div_sl = false; //Allow Divergence based stoploss
input string g7 = ""; //_
input bool tp_fixd = false; //Allow Fixed TakeProfit
input bool sl_fixd = false; //Allow Fixed StopLoss
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input string h8 = ""; //_
input bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
input double risk_reward_tp = 2; //Risk to Reward Ratio for TP
input bool div_close = false; //Allow Divergence based closing
input bool close_trades = true; //Close all trades when trade doesn't execute

 bool breakeven_exit = false; //Breakeven Exit //this is not needed
 int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
 bool sl_breakeven = false; //Allow SL to Move to Breakeven price //this is not needed
  double breakeven_ratio = 1; // Breakeven Ratio //not needed
 double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price  //not needed

input string blank = " "; //_
input string blank2 = " "; //_

input string mtgl_param = " "; //Fill Martingale Inputs
input bool allow_mtgl = true; //Allow Martingale
input double mtgl_risk_reward_tp = 2; //tp for mtgl
input double mtgl_multiplier = 2; //Martingale Multiplier
input int _slippage = 0; //slippage for pending orders in pips
input double swap = 0; //Swap for mtgl in pips
input double commission = 1; //Commission for mtgl in pips

input string blank1 = " "; //_
input string blank3 = " "; //_

input bool allow_ma = false; //Allow MA in Entry Condition
input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES higher_timeframe = PERIOD_M5; //Timeframe for Divergence of higher timeframe
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Divergence of lower timeframe
input int _start = 3; //Start Time of EA
input int end = 23; //End Time of EA

double ma, div_reg, div_hid, ma2;
double high3, low3;
bool trade_check = false;
datetime history_start = TimeCurrent(), trade_close_shift;

double low_of_hid_bull, high_of_hid_bear, low_of_hid_bull2, high_of_hid_bear2;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime hid_bull_div_time, hid_bear_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp;

datetime reg_bear_lp, reg_bull_lp;
double low_of_reg_bull, high_of_reg_bear, low_of_reg_bull2, high_of_reg_bear2;
datetime prev_reg_bull_div_curr_time, prev_reg_bear_div_curr_time;
datetime reg_bull_div_time, reg_bear_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time;

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
   MqlDateTime date;
   TimeCurrent(date);
   SymbolInfoTick(_Symbol, latest_price);
   
   if(allow_mtgl)
   {
     bool reached = false;
     ZonePosition.OnTick(reached);     
   }
  

   ma = iMA(_Symbol, lower_timeframe, ma_periodd, 0, ma_methodd, ma_appliedprice, 1);

   //if the close > open, its a white candle. if the open > close, its a red candle
   double open, low=0, high=0, close, candle = 0;
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
  
  
   if (trade_check == true && hasMarketOrder() == false)
   {
   trade_check = false;
   trade_close_shift = iTime(_Symbol, lower_timeframe, 0);
   }
  
  
   if (use_zz == true)   //for hidden divergence
   {
   hidden_divergence(zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, higher_timeframe, div_lookback,
              high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
              hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 3, bear_color, bull_color, fonts);
   }
   
   if (use_zz2 == true)  //for hidden divergence
   {
   hidden_divergence(zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, higher_timeframe, div_lookback,
              high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
              hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 2, bear_color, bull_color, fonts);
   }
             
   if (use_zz3 == true) //for hidden divergence
   {
   hidden_divergence(zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, higher_timeframe, div_lookback,   
              high_of_hid_bear2, low_of_hid_bull2, high_of_hid_bear, low_of_hid_bull, hid_bear_div_time, hid_bull_div_time, 
              hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp, 1, bear_color, bull_color, fonts);
   }
   
//---

   if (use_zz == true)   //for regular divergence
   {
   regular_divergence(zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, div_lookback, 
               high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 3, bear_color, bull_color, fonts);
   }
   
   if (use_zz2 == true)  //for regular divergence
   {
   regular_divergence(zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, div_lookback, 
              high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 2, bear_color, bull_color, fonts);
   }
             
   if (use_zz3 == true) //for regular divergence
   {
   regular_divergence(zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, div_lookback, 
              high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 1, bear_color, bull_color, fonts);
   }
 

   
   int highest2 = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, reg_bear_div_curr_time), 1);
   double high2 = iHigh(_Symbol, lower_timeframe, highest2);
   
   int highest1 = iHighest(_Symbol, higher_timeframe, MODE_HIGH, iBarShift(_Symbol, higher_timeframe, hid_bear_div_curr_time), 1);
   double high1 = iHigh(_Symbol, higher_timeframe, highest1);
   
   ma2 = iMA(_Symbol, higher_timeframe, ma_periodd, 0, ma_methodd, ma_appliedprice, iBarShift(_Symbol, higher_timeframe, hid_bear_div_curr_time));

   
   bool ma_check = ((allow_ma == true && high < ma && ma2 > high_of_hid_bear2) || (allow_ma == false));
   
   if (trade_close_shift <= hid_bear_div_curr_time && hid_bear_div_curr_time <= reg_bear_div_curr_time && high2 == high_of_reg_bear2 && high1 == high_of_hid_bear2 && high2 >= high_of_hid_bear2 && candle == 1 && high == open && ma_check == true && hasMarketOrder() == false && 
       high2 <= high_of_hid_bear && iTime(_Symbol, lower_timeframe, 1) >= reg_bear_div_curr_time && reg_bear_div_curr_time != prev_reg_bear_div_curr_time && hid_bear_div_curr_time != prev_hid_bear_div_time)
   {                             
         double price = NormalizeDouble(latest_price.bid,_Digits);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? high_of_reg_bear2:sl_fixd ? price + (_Point*(fixed_pips_sl*10)):0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > price ? slt - price:price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         double volume = use_inital_lots == true ? inital_lots:Lots; 

         double sl = slt != 0 ? slt + (_Point*(pips_for_sl*10)):0;
         double tp = tp_rsk_rwrd ? NormalizeDouble(price - (price > sl ? ((price - sl) * risk_reward_tp) : ((sl - price) * risk_reward_tp) ), _Digits):tp_fixd ? price - (_Point*(fixed_pips_tp*10)):0;
                                            
         int res = 0;
         if(date.hour >= _start && date.hour < end )
         res = OrderSend(_Symbol, OP_SELL, volume, price, 0, sl, tp, "sell trade");
       
         if(res > 0) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bear_div_time = hid_bear_div_curr_time;
           prev_reg_bear_div_curr_time = reg_bear_div_curr_time;
           high3 = sl;
           low3 = price;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print("hid div curr = ",hid_bear_div_curr_time,"  reg div curr = ",reg_bear_div_curr_time,"  high1 of hid div = ",iHigh(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bear_div_time)),"  high2 of hid div = ",high_of_hid_bear2,"");
           trade_check = true;
           
           if(allow_mtgl)
           {
             ZonePosition = new ZPClass((high3 - low3)*mtgl_risk_reward_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(res);
           }
           
         }
         else if (res < 0)
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   
  
  
   
   int lowest2 = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, reg_bull_div_curr_time), 1);
   double low2 =  iLow(_Symbol, lower_timeframe, lowest2);
   
   int lowest1 = iLowest(_Symbol, higher_timeframe, MODE_LOW, iBarShift(_Symbol, higher_timeframe, hid_bull_div_curr_time), 1);
   double low1 =  iLow(_Symbol, higher_timeframe, lowest1);
   
   ma2 = iMA(_Symbol, higher_timeframe, ma_periodd, 0, ma_methodd, ma_appliedprice, iBarShift(_Symbol, higher_timeframe, hid_bull_div_curr_time));
   bool ma_check2 = ((allow_ma == true && low > ma && ma2 < low_of_hid_bull2) || (allow_ma == false));
   
  // Print("cond 1 = ",trade_close_shift <= hid_bull_div_curr_time && hid_bull_div_curr_time <= reg_bull_div_time,"   cond 2 = ",low2 == low_of_reg_bull && low2 <= low_of_hid_bull,"   cond 3 = ",candle[0] == 0 && low[0] == open[0] && ma_check2 == true," ");
   //Print(" cond 4 = ",low2 >= iLow(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bull_div_time)),"   cond 5 = ",iTime(_Symbol, lower_timeframe, 1) >= reg_bull_div_time,"  cond 6 = ",reg_bull_div_time != prev_reg_bull_div_time && hid_bull_div_curr_time != prev_hid_bull_div_time,"");
   if (trade_close_shift <= hid_bull_div_curr_time && hid_bull_div_curr_time <= reg_bull_div_curr_time && low2 == low_of_reg_bull2 && low1 == low_of_hid_bull2 && low2 <= low_of_hid_bull2 && candle == 0 && low == open && ma_check2 == true && hasMarketOrder() == false &&
       low2 >= low_of_hid_bull && iTime(_Symbol, lower_timeframe, 1) >= reg_bull_div_curr_time && reg_bull_div_curr_time != prev_reg_bull_div_time && hid_bull_div_curr_time != prev_hid_bull_div_time)
   {
         double price = NormalizeDouble(latest_price.ask,_Digits);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? low_of_reg_bull2:sl_fixd ? price - (_Point*(fixed_pips_sl*10)):0;
         double pips = (price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
      
         double volume = use_inital_lots == true ? inital_lots:Lots; 
         
         double sl = slt != 0 ? slt - (_Point*(pips_for_sl*10)):0;
         double tp = tp_rsk_rwrd ? NormalizeDouble(price + ( price > sl ? ((price - sl) * risk_reward_tp) : ((sl - price) * risk_reward_tp) ), _Digits):tp_fixd ? price + (_Point*(fixed_pips_tp*10)):0;                                  
 
         int res = 0;
         if(date.hour >= _start && date.hour < end )
         res = OrderSend(_Symbol, OP_BUY, volume, price, 0, sl, tp, "buy trade");
         
         if(res > 0) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bull_div_time = reg_bull_div_curr_time;
           prev_hid_bull_div_time = hid_bull_div_curr_time;
           high3 =price;
           low3 = sl;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           Print("hid div curr = ",hid_bull_div_curr_time,"  reg div curr = ",reg_bull_div_curr_time,"  low1 of hid div = ",iLow(_Symbol, higher_timeframe, iBarShift(_Symbol, higher_timeframe, hid_bull_div_time)),"  low2 of hid div = ",low_of_hid_bull2,"");
           trade_check = true;
           
           if(allow_mtgl)
           {
             ZonePosition = new ZPClass((high3 - low3)*mtgl_risk_reward_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(res);
           }
           
         }
         else if(res < 0)
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   
   
   //this is not needed
   //closing when total profit is 0 only when the breakeven exit is allowed
   //if(breakeven_exit == true && PositionsTotal() >= trades_for_breakeven)  //this does not work properly, it has to know how many positions are in a symbol exactly and not take the total positions
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
    
          if ( type == OP_BUY && OrderSymbol() == _Symbol )
          {
              //not needed
      //      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      //      {
      //         mrequest.action = TRADE_ACTION_SLTP;
      //         mrequest.position = PositionGetInteger(POSITION_TICKET);
      //         mrequest.symbol = _Symbol;
      //         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
      //         mrequest.tp = PositionGetDouble(POSITION_TP);
      //      
      //         bool res = OrderSend(mrequest, mresult);
      //      }
            
            if ( div_close == true && OrderOpenTime() <= reg_bear_div_curr_time ) 
            {
               bool res = OrderClose(OrderTicket(), OrderLots(), Bid, 0);
            } 
          }
          
          
          if ( type == OP_SELL && OrderSymbol() == _Symbol )
          {
              //not needed
      //      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      //      {
      //         mrequest.action = TRADE_ACTION_SLTP;
      //         mrequest.position = PositionGetTicket(i);
      //         mrequest.symbol = _Symbol;
      //         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
      //         mrequest.tp = PositionGetDouble(POSITION_TP); 
      //      
      //         bool res = OrderSend(mrequest, mresult);
      //      } 
            
         
            if ( div_close == true && OrderOpenTime() <= reg_bull_div_curr_time ) 
            {
                bool res = OrderClose(OrderTicket(), OrderLots(), Ask, 0);
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


/*buy conditions:
check if regular divergence comes at or after the time hidden divergence came
check if price had not crossed regular divergence's 2nd low

regular divergence's second low should be in between the price of hidden divergence's 2nd low and hidden divergence's 1st low
strong heikan ashi candle (without shadow) for entry signal

same goes for sell*/

//make sure to add breakeven pips to breakeven logic
