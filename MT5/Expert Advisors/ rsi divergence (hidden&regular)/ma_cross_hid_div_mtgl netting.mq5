//+------------------------------------------------------------------+
//|                                ma_cross_hid_div_mtgl netting.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"

#include <ZonePosition.mqh>
#define ZPClass CZonePosition

//EA LOGIC DESCRIPTION : rsi hidden divergence and ma cross. 
//heiken ashi candle for entry;
//zz low/high sl, 1st div low/high sl and fixed sl are used. for tp, risk-reward and fixed tp are used
//uses multi degree divergence's and the latest one is used for entry
//mtgl 1 and mtgl 2 exits added
//added first zz high/low based sl. this puts the sl at the zz high/low previous to the latest one
//added zz4_shift for the shift to start looking for zz high/lows for sl and mtgl1 to avoid putting sl at
//zz high/low which is at shift 0

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. the lotise for each mtgl trade is calculated differently

//netting will start based on wherever the sl level is. the sl won't actually be there in the the first trade but the netting will start at 
//that level

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql5.mqh or in the ZonePosition_Nett.mqh file, you must compile this ea also

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

input string ____ = " "; //  

input string zz_param = " "; //Fill ZigZag Parameters
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

input int zz_arrow_depth4 = 3; //Fourth Depth for ZZ Sl
input int zz_arrow_deviation4 = 2; //Fourth Depth for ZZ Sl
input int zz_arrow_backStep4 = 2; //Fourth Depth for ZZ Sl
input int zz4_shift = 1; //ZigZag Shift(shift to start looking for zz highs/lows for sl)
input string blank1 = " "; // " "
input string note1 = ""; //the fourth zz will be where netting starts if no sl is there
input string note2 = ""; //but if there is, netting will start at that sl

input string __ = " "; // " "

//param for ma
input string ma_param = " "; //EMA Parameters
input ENUM_APPLIED_PRICE ma_appliedprice = PRICE_CLOSE; //EMA Applied Price
input ENUM_MA_METHOD ma_methodd = MODE_EMA; //EMA Method
input int ma_periodd_slow = 200; //Slow EMA Period
input int ma_periodd_fast = 50; //Fast EMA Period

input string blank2 = " "; //_

//parameters for ea
input string ea_param = " ";  //Fill Ea Parameters Below
input bool div_above_ma = false; //High/Low 2 of Divergence Above/Below Slow ma
 bool sl_breakeven = false; //Allow SL to Move to Breakeven price
 bool first_hi_low = false; //Allow SL to be 1st ZZ high/low Based
input bool zigzag_sl = false; //Allow ZigZag based stoploss (to get level for netting)
input bool tp_fixd = false; //Allow Fixed TakeProfit
 bool sl_fixd = false; //Allow Fixed StopLoss
input bool div_sl = false; //Allow Divergence based stoploss (to get level for netting)
 bool tp_rsk_rwrd = false; //Allow Risk-Reward Based TakeProfit
 input bool first_trade_exit = true; //Allow First trade exit
input bool heiken_close = false; //Heiken Ashi Close Exit
input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input bool close_trades = true; //Close all trades when trade doesn't execute

input string blank = " "; //_

 double fixed_pips_sl = 10; //Pips for Fixed StopLoss
 double pips_for_sl = 1; //Amount of pips to be added/subtracted from stoploss
 double breakeven_ratio = 1; // Breakeven Ratio
 double breakeven_pips = 1; //Pips to Be Added/Subtracted from Breakeven price
input double swap = 0; //Swap for mtgl in pips
input double commission = 0; //Commission for mtgl in pips
input double first_trade_exit_ratio = 1; //First Trade Exit Ratio (for first trade only) 
input double risk_reward_tp = 2; //Risk to Reward Ratio for mtgl
input double mtgl_multiplier = 2; //Martingale Multiplier
input double fixed_pips_tp = 5; //Pips for Fixed TakeProfit
input bool use_risk_lots = false; //Use %Risk Based Lots 
input bool use_inital_lots = true; //Use Initial Lots
input double inital_lots = 0.01; //Initial Lots
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input ENUM_TIMEFRAMES lower_timeframe = PERIOD_M1; //Timeframe for Trade Entry
input int start = 3; //Start Time of EA
input int end = 23; //End Time of EA

ulong stat_ticket;
int ma_handle, ma_handle2, hkn_ashi_handle, zz_handle, zz_handle2, counter = 0;
datetime bullish_cross, bearish_cross, heiken_bull, heiken_bear, trade_close_shift;
double ma_fast[], div_reg[], div_hid[], ma_slow[], ma_slow2[], low_of_hid_bull, high_of_hid_bear, low_of_hid_bull2, high_of_hid_bear2;
datetime prev_hid_bull_div_time, prev_reg_bull_div_time, prev_reg_bear_div_time, prev_hid_bear_div_time, trade_time;
datetime hid_bull_div_time, hid_bear_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp;
double high3, low3, percent_counter = 0;
bool trade_check = false;
datetime history_start = TimeCurrent();

ZPClass *ZonePosition;

int OnInit(void)
{
   ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, false, false, false, true, 0.0, 0.0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
delete ZonePosition;

   IndicatorRelease(ma_handle);
   IndicatorRelease(ma_handle2);
   IndicatorRelease(hkn_ashi_handle);
   IndicatorRelease(zz_handle);
   IndicatorRelease(zz_handle2);
   
}


void divergence(double& zigzagup, double& zigzagdown, double& zigzagup2, double& zigzagdown2, datetime& zigzaguptime, datetime& zigzagdowntime, datetime& zigzaguptime2, datetime& zigzagdowntime2, 
                int depth, int deviation, int backstep, ENUM_TIMEFRAMES tf, //for zz settings and timeframe
                double& hid_bear_div_hi, double& hid_bull_div_lo, double& hid_bear_div_hi2, double& hid_bull_div_lo2,/*for hidden divergence*/
                datetime& hid_bear_div_time_, datetime& hid_bull_div_time_, datetime& hid_bear_div_time_curr_, datetime& hid_bull_div_time_curr_, datetime& hid_bear_lp_, datetime& hid_bull_lp_ /*for hidden divergence*/) 
{

   zz_handle = iCustom(_Symbol,tf,"\\Indicators\\Examples\\ZigZag.ex5",depth,deviation,backstep);
   double zz_high[], zz_low[], zz_col[];
   CopyBuffer(zz_handle, 1, 0, 301, zz_high);
   CopyBuffer(zz_handle, 2, 0, 301, zz_low);
   CopyBuffer(zz_handle, 0, 0, 301, zz_col);
   ArraySetAsSeries(zz_high, true);
   ArraySetAsSeries(zz_low, true);
   ArraySetAsSeries(zz_col, true);
   
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= 1 ; i<100; i++)
     {
      double downarrow=zz_high[i]; //up val
      double zero=zz_col[i];
      if(downarrow>0 && zero > 0)
        {
         zigzagdowntime = iTime(_Symbol,tf,i);
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
         zigzagdowntime2 = iTime(_Symbol,tf,i);
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

         zigzaguptime = iTime(_Symbol,tf,i);
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
         zigzaguptime2 = iTime(_Symbol,tf,i);
         zigzagup2 = uparrow;
         break;
        }
     }
     
     
   if(zigzagdown < zigzagdown2  && zigzaguptime < zigzagdowntime) //hidden bearish
   {
         int to = iBarShift(_Symbol,tf,zigzaguptime2);
         int from = iBarShift(_Symbol,tf,zigzagdowntime2);
         double first_rsi = maxRSIValue(from , to, tf);
         datetime first_rsi_time = maxRSITime(from , to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzaguptime);
         int from2 = iBarShift(_Symbol,tf,zigzagdowntime);
         double second_rsi = maxRSIValue(from2 , to2, tf);
         datetime second_rsi_time = maxRSITime(from2 , to2, tf);
         if(first_rsi < second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,"firstReversal1",clrMaroon);  
            TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,"firstReversal2",clrMaroon);  
          
            hid_bear_div_time_ = zigzagdowntime2;
            hid_bear_div_time_curr_ = zigzagdowntime;
            hid_bear_div_hi = zigzagdown2;
            hid_bear_div_hi2 = zigzagdown;
            hid_bear_lp_ = zigzaguptime2;
         }
   }
   
   if(zigzaguptime > zigzagdowntime && zigzagup > zigzagup2) //hidden bullish
   {
         int to = iBarShift(_Symbol,tf,zigzagdowntime2);
         int from = iBarShift(_Symbol,tf,zigzaguptime2);
         double first_rsi = minRSIValue(from , to, tf);
         datetime first_rsi_time = minRSITime(from , to, tf);
         int to2 = iBarShift(_Symbol,tf,zigzagdowntime);
         int from2 = iBarShift(_Symbol,tf,zigzaguptime);
         double second_rsi = minRSIValue(from2 , to2, tf);
         datetime second_rsi_time = minRSITime(from2 , to2, tf);
         if(first_rsi > second_rsi)
         {
            TrendDelete(0,"firstReversal1");
            TrendDelete(0,"firstReversal2");     
            TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,"firstReversal1",clrGreen);  
            TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,"firstReversal2",clrGreen);     
        
            hid_bull_div_time_ = zigzaguptime2;
            hid_bull_div_time_curr_ = zigzaguptime;
            hid_bull_div_lo = zigzagup2;
            hid_bull_div_lo2 = zigzagup;
            hid_bull_lp_ = zigzagdowntime2;
         }
   }
   
}


void OnTick()
{

   ma_handle = iMA(_Symbol, lower_timeframe, ma_periodd_fast, 0, ma_methodd, ma_appliedprice);
   ma_handle2 = iMA(_Symbol, lower_timeframe, ma_periodd_slow, 0, ma_methodd, ma_appliedprice);
   
   MqlTick latest_price;
   MqlTradeRequest mrequest;
   MqlTradeResult mresult;
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   SymbolInfoTick(_Symbol, latest_price);
   MqlDateTime date;
   TimeCurrent(date);
   MqlDateTime date2;
  
   CopyBuffer(ma_handle, 0, 1, 2, ma_fast);
   ArraySetAsSeries(ma_fast, true);
   CopyBuffer(ma_handle2, 0, 1, 2, ma_slow);
   ArraySetAsSeries(ma_slow, true);
   
   double candle[], open[], low[], high[], close[];
   hkn_ashi_handle = iCustom(_Symbol, lower_timeframe, "Heiken_Ashi");
   CopyBuffer(hkn_ashi_handle, 4, 1, 1, candle);  //0 for blue candles and 1 for red candles
   CopyBuffer(hkn_ashi_handle, 3, 1, 1, close);  //close
   CopyBuffer(hkn_ashi_handle, 2, 1, 1, low);  //low
   CopyBuffer(hkn_ashi_handle, 1, 1, 1, high);  //high
   CopyBuffer(hkn_ashi_handle, 0, 1, 1, open);  //open
   
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
   int two_up1=0,two_down1=0,second_two_up1=0,second_two_down1=0;
   
if (use_zz == true)   //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, lower_timeframe, 
           high_of_hid_bear, low_of_hid_bull, high_of_hid_bear2, low_of_hid_bull2, hid_bear_div_time, hid_bull_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp);
}

if (use_zz2 == true)  //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, lower_timeframe, 
           high_of_hid_bear, low_of_hid_bull, high_of_hid_bear2, low_of_hid_bull2, hid_bear_div_time, hid_bull_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp);
}
          
if (use_zz3 == true) //for regular divergence
{
divergence(zigzagup, zigzagdown, zigzagup2, zigzagdown2, zigzaguptime, zigzagdowntime, zigzaguptime2, zigzagdowntime2, zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, lower_timeframe, 
           high_of_hid_bear, low_of_hid_bull, high_of_hid_bear2, low_of_hid_bull2, hid_bear_div_time, hid_bull_div_time, hid_bear_div_curr_time, hid_bull_div_curr_time, hid_bear_lp, hid_bull_lp);
}
     

 zigzagup=0;
 zigzagup2=0;
 zigzagdown=0;
 zigzagdown2=0;
 zigzagdowntime=NULL;zigzagdowntime2=NULL;
 zigzaguptime = NULL;zigzaguptime2 = NULL;
   
 
    
  zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth4,zz_arrow_deviation4,zz_arrow_backStep4);
  double zz_high2[], zz_low2[], zz_col2[];
  CopyBuffer(zz_handle2, 1, 0, 301, zz_high2);
  CopyBuffer(zz_handle2, 2, 0, 301, zz_low2);
  CopyBuffer(zz_handle2, 0, 0, 301, zz_col2);
  ArraySetAsSeries(zz_high2, true);
  ArraySetAsSeries(zz_low2, true);
  ArraySetAsSeries(zz_col2, true);
  
   int two_up=0,two_down=0,second_two_up=0,second_two_down=0;
   for(int i= zz4_shift ; i<100; i++)
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

   for(int i= zz4_shift ; i<100; i++)
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
 

 
   if (trade_check == true && PositionSelect(_Symbol) == false)
   {
   trade_check = false;
   trade_close_shift = iTime(_Symbol, lower_timeframe, 0);
   }

   ZonePosition.OnTick();
   
   if(ma_fast[1] > ma_slow[1] && ma_slow[0] > ma_fast[0])
   bearish_cross = iTime(_Symbol, lower_timeframe, 1);
  
   if(candle[0] == 1 && ((high[0] == close[0] && open[0] < close[0]) || (high[0] == open[0] && open[0] > close[0])) )
   heiken_bear = iTime(_Symbol, lower_timeframe, 1);
   
   int highest_ind = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, hid_bear_div_time), 1);
   double highest = iHigh(_Symbol, lower_timeframe, highest_ind);
   
   int highest_ind1 = iHighest(_Symbol, lower_timeframe, MODE_HIGH, iBarShift(_Symbol, lower_timeframe, hid_bear_div_curr_time), 1);
   double highest1 = iHigh(_Symbol, lower_timeframe, highest_ind1);
   
   CopyBuffer(ma_handle2, 0, hid_bear_div_curr_time, 1, ma_slow2);
   ArraySetAsSeries(ma_slow2, true);
   bool ma_check = ( (div_above_ma == true && ma_slow2[0] > high_of_hid_bear2) || (div_above_ma == false) );
   
    
   //Print("cond1= ",trade_close_shift <= hid_bear_div_time,"  cond2 = ",hid_bear_div_time != 0 && bearish_cross != 0,"  cond3 = ",hid_bear_div_curr_time >= bearish_cross,"  cond4 = ",heiken_bear >= hid_bear_div_curr_time,"  cond5 = ",hid_bear_div_time != prev_hid_bear_div_time,"  cond6 = ",highest == high_of_hid_bear,"  cond7 = ",highest1 == high_of_hid_bear2,""); 
   if(trade_close_shift <= hid_bear_lp && hid_bear_div_time != 0 && bearish_cross != 0 && hid_bear_div_curr_time >= bearish_cross && heiken_bear >= hid_bear_div_curr_time && PositionSelect(_Symbol) == false && hid_bear_div_time != prev_hid_bear_div_time && 
      highest == high_of_hid_bear && highest1 == high_of_hid_bear2 && ma_slow[0] > ma_fast[0] && ma_check == true)
   {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
         
         
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = sl_fixd ? mrequest.price + (_Point*(fixed_pips_sl*10)) : first_hi_low ? zigzagdown2 : first_trade_exit ? 0:0; //ratio based sl (it will change to breakeven when price reaches a certain price which is maybe half the tp )
         double pips = (slt > mrequest.price ? slt - mrequest.price:mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         double tp2 = NormalizeDouble(mrequest.price - (mrequest.price > zigzagdown ? ((mrequest.price - zigzagdown)*first_trade_exit_ratio) : ((zigzagdown - mrequest.price)*first_trade_exit_ratio)), _Digits);
         
         mrequest.sl = slt != 0 ? slt + (_Point*(pips_for_sl*10)):0;
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price - ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : tp_fixd ? mrequest.price - (_Point*(fixed_pips_tp*10)):
         first_trade_exit ? tp2: 0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = use_inital_lots == true ? inital_lots:Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         TimeToStruct(hid_bear_div_time, date2);
         if(date.hour >= start && date.hour < end /*&& date2.hour >= start && date2.hour < end*/)
         bool res = OrderSend(mrequest, mresult);
       
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bear_div_time = hid_bear_div_time;
           high3 = div_sl ? high_of_hid_bear : zigzag_sl ? zigzagdown : mrequest.sl <= 0 ? zigzagdown : 0;
           low3 = mrequest.price;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           
            point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
            slt = div_sl ? low_of_hid_bull : zigzag_sl ? zigzagup : sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)):0;
            pips = (mrequest.price - slt)/_Point;
            freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
            PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
            Lots = 0.04 * freeMargin / (PipValue * pips);
            Lots = floor(Lots * 100) / 100;
            
           Print(" hid div 2nd high = ",high_of_hid_bear," time of hid div = ",hid_bear_div_curr_time,"  ma slow2 = ",ma_slow2[0],"  1% risk lotsize = ",Lots,"");
           trade_check = true;
           
           ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new ZPClass((high3 - low3)*risk_reward_tp, high3 - low3, mtgl_multiplier, false, true, false, true, swap, commission);
            ZonePosition.OpenPosition(ticket);
          
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
           
         }
   }
   
   
  
   if(ma_slow[1] > ma_fast[1] && ma_fast[0] > ma_slow[0])
   bullish_cross = iTime(_Symbol, lower_timeframe, 1);

   if(candle[0] == 0 && ((low[0] == open[0] && open[0] < close[0]) || (low[0] == close[0] && open[0] > close[0])) )
   heiken_bull = iTime(_Symbol, lower_timeframe, 1);
   
   int lowest_ind = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, hid_bull_div_time), 1);
   double lowest = iLow(_Symbol, lower_timeframe, lowest_ind);
   
   int lowest_ind1 = iLowest(_Symbol, lower_timeframe, MODE_LOW, iBarShift(_Symbol, lower_timeframe, hid_bull_div_curr_time), 1);
   double lowest1 = iLow(_Symbol, lower_timeframe, lowest_ind1);
   
   CopyBuffer(ma_handle2, 0, hid_bull_div_curr_time, 1, ma_slow2);
   ArraySetAsSeries(ma_slow2, true);
   ma_check = ( (div_above_ma == true && ma_slow2[0] < low_of_hid_bull2) || (div_above_ma == false) );
   
   
   //Print("cond1 = ",trade_close_shift <= hid_bull_div_time,"  cond2 = ",hid_bull_div_time != 0 && bullish_cross != 0,"  cond3 = ",hid_bull_div_curr_time >= bullish_cross,"  cond4 = ",heiken_bull >= hid_bull_div_curr_time,"  cond5 = ",hid_bull_div_time != prev_hid_bull_div_time,"  cond6 = ",lowest == low_of_hid_bull,"  cond7 = ",lowest1 == low_of_hid_bull2,"");
   if (trade_close_shift <= hid_bull_lp && hid_bull_div_time != 0 && bullish_cross != 0 && hid_bull_div_curr_time >= bullish_cross && heiken_bull >= hid_bull_div_curr_time && PositionSelect(_Symbol) == false && hid_bull_div_time != prev_hid_bull_div_time &&
       lowest == low_of_hid_bull && lowest1 == low_of_hid_bull2 && ma_fast[0] > ma_slow[0] && ma_check == true)
   {
         mrequest.action = TRADE_ACTION_DEAL; 
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
        
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
         double slt = sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)) : first_hi_low ? zigzagup2 : first_trade_exit ? 0:0;
         double pips = (mrequest.price - slt)/_Point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         double tp2 = NormalizeDouble(mrequest.price - (mrequest.price > zigzagup ? ((mrequest.price - zigzagup)*first_trade_exit_ratio) : ((zigzagup - mrequest.price)*first_trade_exit_ratio)), _Digits);
        
         mrequest.sl = slt != 0 ? slt - (_Point*(pips_for_sl*10)):0;
         mrequest.tp = tp_rsk_rwrd ? NormalizeDouble(mrequest.price + ( mrequest.price > mrequest.sl ? ((mrequest.price - mrequest.sl) * risk_reward_tp) : ((mrequest.sl - mrequest.price) * risk_reward_tp) ), _Digits) : tp_fixd ? mrequest.price + (_Point*(fixed_pips_tp*10)):
         first_trade_exit ? tp2:0;
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = use_inital_lots == true ? inital_lots:Lots;                                           
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                    
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;   
         
         TimeToStruct(hid_bull_div_time, date2);
         if(date.hour >= start && date.hour < end /*&& date2.hour >= start && date2.hour < end*/)
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           trade_time = iTime(_Symbol, lower_timeframe, 0);
           prev_hid_bull_div_time = hid_bull_div_time;
           high3 = mrequest.price;
           low3 = div_sl ? low_of_hid_bull : zigzag_sl ? zigzagup : mrequest.sl <= 0 ? zigzagup : 0;
           history_start = iTime(_Symbol, lower_timeframe, 0);
           
            point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); 
            slt = div_sl ? low_of_hid_bull : zigzag_sl ? zigzagup : sl_fixd ? mrequest.price - (_Point*(fixed_pips_sl*10)):0;
            pips = (mrequest.price - slt)/_Point;
            freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
            PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
            Lots = 0.04 * freeMargin / (PipValue * pips);
            Lots = floor(Lots * 100) / 100;
           
           Print("hid div = ",hid_bull_div_curr_time,"  ma slow2 = ",ma_slow2[0],"  1% risk lotsize = ",Lots,"");
           trade_check = true;
           
           ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new ZPClass((high3 - low3)*risk_reward_tp, high3 - low3, mtgl_multiplier, false, true, false, true, swap, commission);
            ZonePosition.OpenPosition(ticket);

         }
         else
         {
           Print("The buy order request could not be completed -error:",GetLastError());
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
   
 
   //closing when total profit is 0 only when the breakeven exit is allowed
   if(breakeven_exit == true && count >= trades_for_breakeven) 
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
    
    if ( type == POSITION_TYPE_BUY && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetTicket(i) == stat_ticket )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) > (PositionGetDouble(POSITION_PRICE_OPEN) + (breakeven_ratio * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_SL)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetInteger(POSITION_TICKET);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP);
      
         bool res = OrderSend(mrequest, mresult);
      }
      
      if ( candle[0] == 1 && heiken_close == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
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
    
    
    if ( type == POSITION_TYPE_SELL && PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetTicket(i) == stat_ticket )
    {
      if ( iClose(_Symbol, lower_timeframe, 0) < (PositionGetDouble(POSITION_PRICE_OPEN) - (breakeven_ratio * (PositionGetDouble(POSITION_SL) - PositionGetDouble(POSITION_PRICE_OPEN)))) && sl_breakeven == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
      {
         mrequest.action = TRADE_ACTION_SLTP;
         mrequest.position = PositionGetTicket(i);
         mrequest.symbol = _Symbol;
         mrequest.sl = PositionGetDouble(POSITION_PRICE_OPEN); 
         mrequest.tp = PositionGetDouble(POSITION_TP); 
      
         bool res = OrderSend(mrequest, mresult);
      } 
    
      if ( candle[0] == 0 && heiken_close == true ) //for breakeven logic only regardless of whther risk reward closing or divergence closing is allowed or not
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
