//+------------------------------------------------------------------+
//|                                                     zz12_div.mq4 |
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

//EA description: rsi regular divergence and then waverunner 1-2 pattern break 
//added first zz high/low based sl. this puts the sl at the zz high/low previous to the latest one.
//netting is optional.
//this is a copy of the mt5 version of this ea. the only differences is that it has netting and zigzag has been replaced with waverunner.

//added zz4_shift for the shift to start looking for zz high/lows for sl and mtgl1 to avoid putting sl at
//zz high/low which is at shift 0

//added breakout logic. breakout logic ensures that (in case of a buy) when shift 0's high is above previous lower high, shift 0's low
//is less than the previous lower high.
//the opposite happens for a sell

//for the first trade, the range for the tp calculation will be calculated as per whatever you put as the sl. for the netting,
//currently, you have to choose what the range will be based on. either divergence based or zz swing based.

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. 

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql4.mqh file, you must compile this ea also

//IMPORTANT : compile ea before use to get the latest changes made in included mqh files

enum MTGL_RANGELEVEL {
  zigzag,
  divergence
};

input string zz_param = " "; //Fill Waverunner Parameters
input int zz_arrow_depth = 12; //First Depth for Divergence
input int zz_arrow_deviation = 5; //First Deviation for Divergence
input int zz_arrow_backStep = 3; //First Backstep for Divergence
input bool use_zz = true; //Use First Waverunner for Divergence
input string w = " "; //_
input int zz_arrow_depth2 = 8; //Second Depth for Divergence
input int zz_arrow_deviation2 = 5; //Second Deviation for Divergence
input int zz_arrow_backStep2 = 3; //Second Backstep for Divergence
input bool use_zz2 = true; //Use Second Waverunner for Divergence
input string q = " "; //_
input int zz_arrow_depth3 = 3; //Third Depth for Divergence
input int zz_arrow_deviation3 = 2; //Third Depth for Divergence
input int zz_arrow_backStep3 = 2; //Third Depth for Divergence
input bool use_zz3 = true; //Use Third Waverunner for Divergence
input string s = " "; //_
input int zz_arrow_depth4 = 12; //Fourth Depth for Waverunner 1-2 entry
input int zz_arrow_deviation4 = 5; //Fourth Deviation for Waverunner 1-2 entry
input int zz_arrow_backStep4 = 3; //Fourth Backstep for Waverunner 1-2 entry
input int zz4_shift = 0; //Fourth Waverunner Shift (shift to start looking for waverunner highs/lows for sl)
input int fonts = 13; //Font Size of Label
input color bear_color = clrRed; //Colour of Bearish Div
input color bull_color = clrLime; //Colour of Bullish Div
input int div_lookback = 100; //Lookback for Divergence

input string blank2 = " "; //_
input string blank3 = " "; //_

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input string slInputs = " "; //Fill StopLoss & TakeProfit Inputs Below:
input double pips_for_sl = 0; //Amount of pips to be added/subtracted from stoploss
 bool sl_breakeven = false; //Allow SL to Move to Breakeven price //this has been removed from inputs as it is not needed
 double breakeven_ratio = 1; // Breakeven Ratio
 double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price 
input string blb = " "; //_
input bool zigzag_sl = false; //Allow ZigZag based stoploss
input bool first_hi_low = false; //Allow SL to be 1st ZZ high/low Based
input string a1 = " "; //_
input bool tp_fixd = false; //Allow Fixed TakeProfit
input bool sl_fixd = false; //Allow Fixed StopLoss
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input double fixed_pips_sl = 5; //Pips for Fixed StopLoss
input string b2 = " "; //_
input bool div_sl = true; //Allow Divergence based stoploss
input string c3 = " "; //_
input bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
input double risk_reward_tp = 2; //Risk to Reward Ratio for first trade's TP
input string f6 = " "; //_
input bool first_trade_exit = true; //Allow First Trade Exit

input string d4 = " "; //_
input string e5 = " "; //_

input string mtglInputs = " "; //Fill Martingale Inputs Below:
input bool mtgl_allow = true; //Allow Netting 
input double mtgl_multiplier = 0.01; //Martingale Multiplier
input double mtgl_tp = 2; //Martingale TakeProfit Ratio
input MTGL_RANGELEVEL mtgl_range_level = divergence;
input double swap = 0; //Swap for mtgl in pips
input double commission = 1; //Commission for mtgl in pips
input int _slippage = 0; //slippage for pending orders in pips
input string g7 = " "; //_
 bool breakeven_exit = false; //Breakeven Exit //not needed in strategy, so it has been removed
 int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

input string blank = " "; //_
input string h8 = " "; //_

input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int _start = 4; //Start Time of EA
input int end = 23; //End Time of EA

int zz_handle, zz_handle2, counter = 0;
datetime trade_close_shift, reg_bear_lp, reg_bull_lp;
double div_reg[], div_hid[], low_of_reg_bull, high_of_reg_bear, low_of_reg_bull2, high_of_reg_bear2;
datetime prev_hid_bull_div_time, prev_reg_bull_div_curr_time, prev_reg_bear_div_curr_time, prev_hid_bear_div_time, trade_time;
datetime reg_bull_div_time, reg_bear_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time;
double high3, low3;
bool trade_check = false;
datetime history_start = TimeCurrent();

ZPClass *ZonePosition;
int OnInit()
{
  if(mtgl_allow)
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
   MqlDateTime date2;
   
   if(mtgl_allow)
   {
     bool reached = false;
     ZonePosition.OnTick(reached);     
   }

   
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
   int two_up1=0,two_down1=0,second_two_up1=0,second_two_down1=0;
   
if (use_zz == true)   //for regular divergence
{
regular_divergence(zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, div_lookback,
            high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 1, bear_color, bull_color, fonts);
}

if (use_zz2 == true)  //for regular divergence
{
regular_divergence(zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, div_lookback,
           high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 1, bear_color, bull_color, fonts);
}
          
if (use_zz3 == true) //for regular divergence
{
regular_divergence(zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, div_lookback,
           high_of_reg_bear2, low_of_reg_bull2, reg_bear_div_time, reg_bull_div_time, reg_bear_div_curr_time, reg_bull_div_curr_time, reg_bull_lp, reg_bear_lp, 1, bear_color, bull_color, fonts);
}
     

   zigzagup=0;
   zigzagup2=0;
   zigzagdown=0;
   zigzagdown2=0;
   zigzagdowntime=NULL;zigzagdowntime2=NULL;
   zigzaguptime = NULL;zigzaguptime2 = NULL;
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
     
   if(zigzaguptime < zigzagdowntime)  
   {
   end_shift = (two_up+1) + 50;
   for(int i= two_up+1 ; i<end_shift; i++)
     {
      double downarrow= iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagdown2 = downarrow;
         two_up2 = i;
         break;
        }
     }
     
   end_shift = (two_up2+1) + 50;
   for(int i=  two_up2+1 ; i<end_shift; i++)
     {
      double uparrow=iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     }
   }
   
  if(zigzaguptime > zigzagdowntime)  
  {  
   end_shift = (two_down+1) + 50;
   for(int i=  two_down+1 ; i<end_shift; i++)
     {
      double uparrow=iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagup2 = uparrow;
         two_down2 = i;
         break;
        }
     }
     
    end_shift = (two_down2+1) + 50;
    for(int i= two_down2+1 ; i<end_shift; i++)
     {
      double downarrow= iCustom(_Symbol,lower_timeframe,"WaveRunnerConfirm",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,lower_timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }
  }
   
 
   if (trade_check == true && hasMarketOrder() == false)
   {
   trade_check = false;
   trade_close_shift = iTime(_Symbol, lower_timeframe, 0);
   }
   
   
   int highest_ind1 = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, reg_bear_div_curr_time), 1);
   double highest1 = iHigh(_Symbol, lower_timeframe, highest_ind1);
                                  
   //Print("reg bear div time = ",reg_bear_div_time,"  prev reg bear = ",prev_reg_bear_div_time,"  highest1 = ",highest1 ,"");
   //Print(" cond1 =",trade_close_shift <= reg_bear_div_curr_time,"  cond2 = ",reg_bear_div_curr_time != 0,"  cond3 = ",reg_bear_div_curr_time != prev_reg_bear_div_curr_time,"  cond4 = ",highest1 == high_of_reg_bear2,"  cond5 =",zigzagdowntime2 >= reg_bear_div_curr_time,"");  
   
   //Print("zigzagdowntime ",zigzagdowntime,"  zigzaguptime ",zigzaguptime,"  zzdwn = ",zigzagdown," zzdwn2 = ",zigzagdown2,"  zzup = ",zigzagup," zzup2 = ",zigzagup2,"  high = ",iHigh(_Symbol, lower_timeframe, 0),"");
   //Print("cond6 = ",(zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2 && iHigh(_Symbol, lower_timeframe, 0) >= zigzagup2),"");
   //Print("",zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2 && iHigh(_Symbol, lower_timeframe, 0) >= zigzagup,"");
   
   if(trade_close_shift <= reg_bear_div_curr_time && reg_bear_div_curr_time != 0 && hasMarketOrder() == false && reg_bear_div_curr_time != prev_reg_bear_div_curr_time && highest1 == high_of_reg_bear2 && zigzagdowntime2 >= reg_bear_div_curr_time && 
      ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2 && zigzagdown2>0 && zigzagup2>0 && iHigh(_Symbol, lower_timeframe, 0) >= zigzagup2) ||
       (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2 && zigzagdown2>0 && zigzagup2>0 && iHigh(_Symbol, lower_timeframe, 0) >= zigzagup)) )
   {                        
         double price = NormalizeDouble(latest_price.bid,_Digits);
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? high_of_reg_bear2 : zigzag_sl ? zigzagdown : sl_fixd ? price + (_Point*(fixed_pips_sl*10)) : first_hi_low ? zigzagdown2 : first_trade_exit ? 0:0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > price ? slt - price:price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         double sl = slt != 0 ? slt + (_Point*(pips_for_sl*10)):0;
         double tp = tp_rsk_rwrd ? NormalizeDouble(price - ( price > sl ? ((price - sl) * risk_reward_tp) : ((sl - price) * risk_reward_tp) ), _Digits) : tp_fixd ? price - (_Point*(fixed_pips_tp*10)) : first_trade_exit ? price - (sl-price) : 0;  
         
         int ticket = 0;
         if(date.hour >= _start && date.hour < end)
         ticket = OrderSend(_Symbol, OP_SELL, use_inital_lots ? inital_lots:Lots, price, 100, sl, tp, "sell", 1);
       
         if(ticket > 0) //Request is completed or order placed
         {
           Print("zzdwn = ",zigzagdown,"  zzup = ",zigzagup,"  zzdwn2 = ",zigzagdown2,"  zzup2 = ",zigzagup2,"");
           Print(" ",(zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2),"  ",(zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2)," ");
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           history_start = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bear_div_curr_time = reg_bear_div_curr_time;
           high3 = mtgl_range_level == zigzag ? zigzagdown : mtgl_range_level == divergence ? high_of_reg_bear2 : 0;
           low3 = price;
           trade_check = true;
           
           if(mtgl_allow)
           {
             ZonePosition = new ZPClass((high3 - low3)*mtgl_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(ticket);
           }
         }
         if(ticket < 0)
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
   }
   

   int lowest_ind1 = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, reg_bull_div_curr_time), 1);
   double lowest1 = iLow(_Symbol, lower_timeframe, lowest_ind1);
   
   
   //Print("cond1 = ",trade_close_shift <= reg_bull_div_curr_time,"  cond2 = ",reg_bull_div_curr_time != 0,"  cond3 = ",reg_bull_div_curr_time != prev_reg_bull_div_curr_time,"  cond4 = ",lowest1 == low_of_reg_bull2,"  cond5 = ",zigzaguptime2 >= reg_bull_div_curr_time,"");
    //Print("cond6 = ",((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && iLow(_Symbol, lower_timeframe, 0) <= zigzagdown2) || 
    //(zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2 && iLow(_Symbol, lower_timeframe, 0) <= zigzagdown)),"");
    
   if (trade_close_shift <= reg_bull_div_curr_time && reg_bull_div_curr_time != 0 && hasMarketOrder() == false && reg_bull_div_curr_time != prev_reg_bull_div_curr_time && lowest1 == low_of_reg_bull2 && zigzaguptime2 >= reg_bull_div_curr_time && 
       ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzagdown2>0 && zigzagup2>0 && iLow(_Symbol, lower_timeframe, 0) <= zigzagdown2) || 
       (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2 && zigzagdown2>0 && zigzagup2>0 && iLow(_Symbol, lower_timeframe, 0) <= zigzagdown)) )
   {
         double price = NormalizeDouble(latest_price.ask,_Digits);
        
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = div_sl ? low_of_reg_bull2 : zigzag_sl ? zigzagup : sl_fixd ? price - (_Point*(fixed_pips_sl*10)) : first_hi_low ? zigzagup2 : first_trade_exit ? 0 : 0;
         double pips = (price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         double sl = slt != 0 ? slt - (_Point*(pips_for_sl*10)):0;
         double tp = tp_rsk_rwrd ? NormalizeDouble(price + ( price > sl ? ((price - sl) * risk_reward_tp) : ((sl - price) * risk_reward_tp) ), _Digits) : tp_fixd ? price + (_Point*(fixed_pips_tp*10)) : first_trade_exit ? price + (price-sl) : 0;
          
         int ticket = 0; 
         //Print("buy order execution about to happen");
         if(date.hour >= _start && date.hour < end)
         ticket = OrderSend(_Symbol, OP_BUY, use_inital_lots ? inital_lots:Lots, price, 100, sl, tp, "buy", 1);
         
         if(ticket > 0) //Request is completed or order placed
         {
           Print("up = ",zigzagdown,"  dwn = ",zigzagup,"  up2 = ",zigzagdown2,"  dwn2 = ",zigzagup2,"");
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           history_start = iTime(_Symbol, lower_timeframe, 0);
           prev_reg_bull_div_curr_time = reg_bull_div_curr_time;
           high3 = price;
           low3 = mtgl_range_level == zigzag ? zigzagup : mtgl_range_level == divergence ? low_of_reg_bull2 : 0;;
           trade_check = true;
           
           if(mtgl_allow)
           {
             ZonePosition = new ZPClass((high3 - low3)*mtgl_tp, high3 - low3, mtgl_multiplier, swap, commission, _slippage);
             ZonePosition.OpenPosition(ticket);
           }
         }
         if(ticket < 0)
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
   //if(breakeven_exit == true && count >= trades_for_breakeven)  //this is not needed in current strategy. so it has been commented
   //{ 
   //  if(profit_total(_Symbol) >= 0)
   //  {
   //    close_all(_Symbol);
   //  }
   //}
 
 
 
//    for(int i = OrdersTotal()-1; i >= 0; i--) //this is not to be used in this strategy, so this has been commented
//    {
//      if(OrderSelect(i, SELECT_BY_POS))
//      {
//          if ( OrderType() == OP_BUY && OrderSymbol() == _Symbol )
//          {
//            if ( iClose(_Symbol, lower_timeframe, 0) > (OrderOpenPrice() + (breakeven_ratio * (OrderOpenPrice() - OrderStopLoss()))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
//            {
//               bool res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
//               if(!res) Print("could not modify sl to the open price. error: ",GetLastError());
//            }
//          }
//          
//          
//          if ( OrderType() == OP_SELL && OrderSymbol() == _Symbol )
//          {
//            if ( iClose(_Symbol, lower_timeframe, 0) < (OrderOpenPrice() - (breakeven_ratio * (OrderStopLoss() - OrderOpenPrice()))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
//            {
//               bool res = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0);
//               if(!res) Print("could not modify sl to the open price. error: ",GetLastError());
//            } 
//          }
//      }
//    }
   
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


  
//do a check to make sure that this is the first time the ea is running using a bool variable          
//if it is the first time, run a loop to check for 4 points of zz pattern

//if it isnt and zigzag value of current bar != 0, replace  variable which holds zigzagdown2/zigzagup2 value with zigzagup/zigzagdown
//zigzagdown2/zigzagup2

//------- logic for calculating latest 4 zz points

//1. calculate all 4 zz points at the start of ea 
//2. get all those point's time

// 3. update the latest zz point when there is a zz high/zz low val on shift 0 and it is not equal to the latest zz point
// 4. if there is a zz value on shift 0 and its type is not equal to the latest zz point's type, 
// 
