//+------------------------------------------------------------------+
//|                                        zigzag_fibret_netting.mq5 |
//|                                                          Samaara |
//|                                             dassamaara@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Samaara"
#property link      "dassamaara@gmail.com"
#property version   "1.00"

#resource "\\Indicators\\Examples\\ZigZag.ex5"
#include <ZonePosition.mqh>
#define ZPClass CZonePosition

//EA Description : this has 2 options for entry, either bb (bb is commented) or zz breakout with fib retracement. this has diveregnce also. 
//and this has mtgl and breakeven 
//first trade exit added
//added breakout logic to ensure the breakout happened exactly at the breakout level and not somewhere higher/lower.
//the above may work most of the times

//this has 2 types of entries: breakout and limit entries.
//breakout will happen if there is a higher high with a higher low/lower low with a lower high. And also making sure that the second high/low 
//did not go below/above a certain point
//limit entries will enter trade when price has reached a certain level

//this ea has a logic in it which makes sure that it does not take trades when the ea is just loaded on the chart. instead it will wait for a new leg
//and then check if there is a signal or not to take a trade.

//this ea also counts the number of martingale sets which have happened

//this ea contains ORCHARD MTGL. there is one of his martingales in this ea. this mtgl only opens one entry at a time and opens it at the zone high/low 
//and closes the previous mtgl trade. the lotise for each mtgl trade is calculated differently

//make sure that whenever changes are made in the ZonePosition.mqh file or in the ZonePosition_mql5.mqh or in the ZonePosition_Nett.mqh file, you must compile this ea also

#include <multidiv.mqh>

//parameters for bb
 string bb_param = " ";  //Fill Bollinger Bands Parameters Below
 int bbmaperiod = 20;    //First Bollinger Bands MA Period
 double bb_dev = 2.0;    //Deviation for First Bollinger Band
 ENUM_APPLIED_PRICE bbappliedprice = PRICE_CLOSE; //Applied First Bollinger Band Price
 int bbmaperiod2 = 20;    //Second Bollinger Bands MA Period
 double bb_dev2 = 2.0;    //Deviation for Second Bollinger Band
  ENUM_APPLIED_PRICE bbappliedprice2 = PRICE_CLOSE; //Applied Second Bollinger Band Price

string ____ = " "; //  " "

//parameters for zz
input string zz_param = " "; //Fill WaveRunner Parameters
input int zz_arrow_depth = 3; //Depth 1
input int zz_arrow_deviation = 2; //Deviation 1
input int zz_arrow_backStep = 2; //Backstep 1
input bool allow_zz1 = true; //Use First waverunr  (for divergence, fib & sl)

input string zz_param2 = " "; //" "
input int zz_arrow_depth2 = 8; //Depth 2  
input int zz_arrow_deviation2 = 5; //Deviation 2
input int zz_arrow_backStep2 = 3; //Backstep 2
input bool allow_zz2 = true; //Use Second waverunr  (for divergence only)

input string zz_param3 = " "; //" "
input int zz_arrow_depth3 = 12; //Depth 3
input int zz_arrow_deviation3 = 5; //Deviation 3
input int zz_arrow_backStep3 = 3; //Backstep 3
input bool allow_zz3 = true; //Use Third waverunr  (for divergence only)


input string blank1 = " "; //" "

//parameters for ea

input string blank2 = " "; // Martingale Parameters Below
input bool first_trade_exit = false; //First Trade Exit (1:1 risk-reward) and No Risk-Reward
input double mtgl_multiplier = 2; //Martingale Multiplier
input double max_pips = 15; //Min range for mtgl for limit entry (in pips)

input string blank3 = " "; // " "

input string blank4 = " "; // Martingale & Non-Martingale Parameters Below
input double swap = 0; //Swap for mtgl in pips
input double commission = 0; //Commission for mtgl in pips
input bool use_inital_lots = true; //Use Fixed Lots
input double initial_lots = 0.01; //Initial Lotsize
input double Risk = 0.01; // % Risk as per equity (0.01 = 1%)
input bool breakeven_exit = false; //Breakeven Exit
input int trades_for_breakeven = 2; //Trades Needed for Breakeven Exit to Apply
input double risk_reward_tp = 2; //Risk-Reward TP for mtgl
input double first_trade_exit_ratio = 1; //First Trade Exit Ratio (for first trade only) 
input double bo_percentage = 50; //Breakout Percentage 
input double li_percentage = 50; //Limit Percentage 

input string blank5 = " "; // " "

input int    starttime = 4; //Start Time of EA
input int    endtime = 23; //End Time of EA
 bool   allow_zz = true; //Allow ZigZag based entry
input bool   allow_div = false; //Allow Divergence with ZigZag entry
input bool   allow_fib = true; //Allow Fib with ZigZag Entry
input bool   allow_bo_entry = true; //Allow Breakout Entries
input bool   allow_limit_entry = true; //Allow Limit Entries 
input string note1 = ""; //limit entries happen if fib entries are allowed.
input string note2 = ""; //if fib entries are allowed and you dont want limit entries,
input string note3 = ""; // the "Allow Limit Entries" input can be made false.

int bb_handle, bb_handle2; 
double bb_upper, bb_lower;
double bb_lower2, bb_upper2;

ENUM_TIMEFRAMES lower_timeframe = PERIOD_CURRENT; //Timeframe for Trade Entry
datetime start = TimeCurrent(); 
ulong stat_ticket;
bool trade_check = false, start_zz_up = false, start_zz_down = false;
int time_of_trade_open, magic_, total_mtgl;
int bb_bar_sell_sig = 0, bb_bar_buy_sig = 0, prev_trade_signal_bar = 0, prev_trade_signal_bar2 = 0, trades_open = 0;
double high, low, bearish_div_high, bullish_div_low;
datetime zz_down_time, zz_up_time, time_of_trade_close = 0, time_of_trade_open2, bearish_div_time, bullish_div_time, start_zz;
 double entryprice_range = 5; //Range For Entry Price 
 double bb_range_high = 16; //Max Size of Range in Pips for BB
 double bb_range_low = 7; //Min Size of Range in Pips for BB
 double zz_range_high = 16; //Max Size of Range in Pips for waverunr
 double zz_range_low = 7; //Min Size of Range in Pips for waverunr
  bool   allow_bb = false; //Allow Bollinger Band based entry (nili aunty said to remove from extern because we are not using it and im not so sure if it works properly becus i added conditions to it and havent tested it)

ZPClass *ZonePosition;

int OnInit()
{
  ZonePosition = new ZPClass(0.0, 0.0, mtgl_multiplier, false, false, false, true, swap, commission);
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
  MqlDateTime date2;
  
  //bb_upper = iBands(_Symbol, lower_timeframe, bbmaperiod, bb_dev, 0, bbappliedprice, MODE_UPPER, 1);
  //bb_upper2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, bb_dev2, 0, bbappliedprice2, MODE_UPPER, 1);
  //bb_lower = iBands(_Symbol, lower_timeframe, bbmaperiod, bb_dev, 0, bbappliedprice, MODE_LOWER, 1);
  //bb_lower2 = iBands(_Symbol, lower_timeframe, bbmaperiod2, bb_dev2, 0, bbappliedprice2, MODE_LOWER, 1);
  
  SymbolInfoTick(_Symbol, latest_price);
  //-----------------
  
  //Print("running");
  ZonePosition.OnTick();
  
  
  int zz_handle2 = iCustom(_Symbol,lower_timeframe,"\\Indicators\\Examples\\ZigZag.ex5",zz_arrow_depth,zz_arrow_deviation,zz_arrow_backStep);
  double zz_high2[], zz_low2[], zz_col2[];
  CopyBuffer(zz_handle2, 1, 0, 301, zz_high2);
  CopyBuffer(zz_handle2, 2, 0, 301, zz_low2);
  CopyBuffer(zz_handle2, 0, 0, 301, zz_col2);
  ArraySetAsSeries(zz_high2, true);
  ArraySetAsSeries(zz_low2, true);
  ArraySetAsSeries(zz_col2, true);
   
   double zigzagup=0;
   double zigzagup2=0;
   double zigzagdown=0;
   double zigzagdown2=0;
   datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
   datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
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
       
     
  if(allow_zz1)
  divergence(zz_arrow_depth, zz_arrow_deviation, zz_arrow_backStep, bullish_div_time, bearish_div_time, bearish_div_high, bullish_div_low, lower_timeframe);

  if(allow_zz2)
  divergence(zz_arrow_depth2, zz_arrow_deviation2, zz_arrow_backStep2, bullish_div_time, bearish_div_time, bearish_div_high, bullish_div_low, lower_timeframe);
  
  if(allow_zz3)
  divergence(zz_arrow_depth3, zz_arrow_deviation3, zz_arrow_backStep3, bullish_div_time, bearish_div_time, bearish_div_high, bullish_div_low, lower_timeframe);


  double div_low = iLow(_Symbol, lower_timeframe, 1);
  for(int i = 1; i <= iBarShift(_Symbol, lower_timeframe, bullish_div_time); i++)
  {
    if(iLow(_Symbol, lower_timeframe, i) < low)
    div_low = iLow(_Symbol, lower_timeframe, i);
  }   
  
  if (trade_check == true && PositionSelect(_Symbol)==false)
  {
  trade_check = false;
  time_of_trade_close = iTime(_Symbol, lower_timeframe, 0);
  }

     
  TimeToStruct(zigzaguptime2, date2);   
  
  if(start == TimeCurrent()) //this wont work if zigzaguptime and zigzagdowntime are on the same leg, so it will execute trade after a signal without waiting for a new leg
  {
    if(zigzagdowntime > zigzaguptime)
    {
      start_zz = zigzaguptime;
      start_zz_up = true;
    }
    
    if(zigzaguptime > zigzagdowntime)
    {
      start_zz = zigzagdowntime;
      start_zz_down = true;
    }
    
  }
     
  if( (start_zz_down && zigzagdowntime > start_zz) || (start_zz_up && zigzaguptime > start_zz) )
  {
  //bb strategy
  double bb_dif = iHigh(_Symbol, lower_timeframe, 1) - iLow(_Symbol, lower_timeframe, 1);
  bool cond_1 = ( (iHigh(_Symbol, lower_timeframe, 1) > bb_upper && iHigh(_Symbol, lower_timeframe, 1) > bb_upper2) && PositionSelect(_Symbol) == false && date.hour >= starttime && date.hour <= endtime && allow_bb );
  bool cond_2 = ( time_of_trade_open != Bars(_Symbol, lower_timeframe) && iClose(_Symbol, lower_timeframe, 1) > iOpen(_Symbol, lower_timeframe, 1) && ((bb_range_high*10)*_Point)>=bb_dif && ((bb_range_low*10)*_Point)<=bb_dif );
  
  bool div_cond1 = bullish_div_time == zigzaguptime2 && allow_div && zigzagup2 == bullish_div_low;
  
  //zz strategy
  double zz_dif = zigzagdowntime >= zigzaguptime ? zigzagdown2 - zigzagup : zigzagdown - zigzagup;
  bool cond_4 = ( ((zigzagdowntime >= zigzaguptime && zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && iLow(_Symbol,lower_timeframe,0) <= zigzagdown2) || (zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 0) > zigzagdown && zigzagup > zigzagup2 && iLow(_Symbol,lower_timeframe,0) <= zigzagdown)) && (div_cond1 || allow_div == false));
                /*(zigzagdowntime <= zigzaguptime && iHigh(_Symbol, lower_timeframe, 1) > zigzagdown && zigzagup > zigzagup2 && iBarShift(_Symbol, lower_timeframe, zigzaguptime) > 0)*/
  
  bool cond_5 = ( zz_down_time != zigzaguptime2 && time_of_trade_close <= zigzaguptime2 && date.hour >= starttime && date.hour < endtime && PositionSelect(_Symbol) == false &&
    ((((zigzagdowntime >= zigzaguptime && zigzagup >= zigzagdown2-percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage)) || (zigzagdowntime <= zigzaguptime && zigzagup >= zigzagdown-percentage_in_pips(zigzagdown, zigzagup2, bo_percentage))) && allow_fib == true) || allow_fib == false) );
  /* && ((zz_range_high*10)*_Point)>=zz_dif && ((zz_range_low*10)*_Point)<=zz_dif (nili aunty said that this condition's not needed)*/
                 
  bool cond_6 = ( (zigzagdowntime <= zigzaguptime && zigzagup > zigzagup2 && iLow(_Symbol,lower_timeframe,0) <= zigzagdown-percentage_in_pips(zigzagdown, zigzagup2, li_percentage)) && allow_fib == true && (div_cond1 || allow_div == false) && PositionSelect(_Symbol) == false && 
    date.hour >= starttime && date.hour < endtime && zz_down_time != zigzaguptime2 && time_of_trade_close <= zigzaguptime2 );
 
 //Print(" cond1 = ",zigzagdowntime <= zigzaguptime," cond2 = ",zigzagup > zigzagup2," cond3 = ",iLow(_Symbol,lower_timeframe,0) <= zigzagdown-percentage_in_pips(zigzagdown, zigzagup2, li_percentage),"  cond4 = ",allow_fib == true,"  cond5 = ",(div_cond1 || allow_div == false),"");
 //Print(" cond 1 = ",cond_4,"  2nd leg% = ",percentage_in_pips(zigzagdown2, zigzagup, 100),"  1st leg% = ",percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage),"  cond 2 = ",( (zigzagdowntime >= zigzaguptime && percentage_in_pips(zigzagdown2, zigzagup, 100) <= percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage)) /*|| (zigzagdowntime <= zigzaguptime && percentage_in_pips(zigzagdown, zigzagup, 100) <= percentage_in_pips(zigzagdown, zigzagup2, bo_percentage))*/ ),"");
 
  if ( (cond_4 && cond_5 && allow_bo_entry) || (cond_6 && allow_limit_entry) )
  {
         
         double sl2 = 0;
         double tp1 = NormalizeDouble(latest_price.ask + ( zigzagup2 > latest_price.ask ? (zigzagup2 - latest_price.ask)*first_trade_exit_ratio : (latest_price.ask - zigzagup2)*first_trade_exit_ratio ), _Digits); 
         double tp2 = NormalizeDouble(latest_price.ask + ( zigzagup > latest_price.ask ? (zigzagup - latest_price.ask)*first_trade_exit_ratio : (latest_price.ask - zigzagup)*first_trade_exit_ratio ), _Digits); 
        
         
         /*if (  ((((NormalizeDouble(latest_price.ask,_Digits) == NormalizeDouble(zigzagdown,_Digits) || (latest_price.ask <= zigzagdown+(entryprice_range*10*_Point) && latest_price.ask > zigzagdown)) && (allow_zz == true || (allow_div && allow_zz))) || 
              ((NormalizeDouble(latest_price.ask,_Digits) == NormalizeDouble(iHigh(_Symbol, lower_timeframe, 0),_Digits) || (latest_price.ask <= (iHigh(_Symbol, lower_timeframe, 0)+(entryprice_range*10*_Point)) && latest_price.ask > iHigh(_Symbol, lower_timeframe, 0))) && zigzagdowntime <= zigzaguptime && (allow_zz == true || (allow_div && allow_zz)))))     ||
              (((NormalizeDouble(latest_price.ask,_Digits) == NormalizeDouble(iHigh(_Symbol, lower_timeframe, 1),_Digits)) || (latest_price.ask <= (iHigh(_Symbol, lower_timeframe, 1)+(entryprice_range*10*_Point)) && latest_price.ask > iHigh(_Symbol, lower_timeframe, 1)))
              && allow_bb == true)  )(nili aunty said not needed)*/
     
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.ask;
         mrequest.sl = first_trade_exit ? sl2: 0;
         mrequest.tp = first_trade_exit && cond_6==true ? tp1 : first_trade_exit && cond_5==true && cond_4==true ? tp2 : 0;
         
         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double pips = (latest_price.ask - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY);
         double PipValue = (((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)));
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100;
         
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = use_inital_lots == true ? initial_lots:Lots;                                          
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_BUY;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;
         
         if( (pip_range(zigzagup2, mrequest.price)==true && cond_6) || !(cond_6) )
         bool res = OrderSend(mrequest, mresult);
   
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           time_of_trade_open = Bars(_Symbol, lower_timeframe);
           time_of_trade_open2 = iTime(_Symbol, lower_timeframe, 0);
           zz_down_time = zigzaguptime2;
           trade_check = true;
           high = mrequest.price;
           low =  cond_6 ? zigzagup2 : cond_4 && cond_5 ? zigzagup : 0;
           total_mtgl = total_mtgl + ZonePosition.GetMtglCount();
           Alert(" total mtgl sets in ",_Symbol," are " ,total_mtgl, " ");
           Print(" for buy | bo % range of prev leg = ",zigzagdown2-percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage),"  limit % range of prev leg = ",zigzagdown-percentage_in_pips(zigzagdown, zigzagup2, li_percentage),"  low = ",iLow(_Symbol,lower_timeframe,0),"  mtgl low = ",low,"");
           //"  100% range for 2nd = ",percentage_in_pips(zigzagdown2, zigzagup, 100),"  zzdwn2 = ",zigzagdown2,"  zzup2 = ",zigzagup2,"  zzup = ",zigzagup,"");
           
           ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new ZPClass((high - low)*risk_reward_tp, high - low, mtgl_multiplier, false, true, false, true, swap, commission);
            ZonePosition.OpenPosition(ticket);
           
         }
         else 
         {
           Print("The buy order request could not be completed -error:",GetLastError());
           ResetLastError();
         }

 
  }

  
  
  double div_high = iLow(_Symbol, lower_timeframe, 1);
  for(int i = 1; i <= iBarShift(_Symbol, lower_timeframe, bearish_div_time); i++)
  {
    if(iHigh(_Symbol, lower_timeframe, i) < low)
    div_high = iHigh(_Symbol, lower_timeframe, i);
  }

  TimeToStruct(zigzagdowntime2, date2);  

  //bb strategy
  bb_dif = iHigh(_Symbol, lower_timeframe, 1) - iLow(_Symbol, lower_timeframe, 1);
  bool cond_11 = ( time_of_trade_open != Bars(_Symbol, lower_timeframe) && iOpen(_Symbol, lower_timeframe, 1) > iClose(_Symbol, lower_timeframe, 1) && ((bb_range_high*10)*_Point)>=bb_dif && ((bb_range_low*10)*_Point)<=bb_dif );
  bool cond_22 = ( (iLow(_Symbol, lower_timeframe, 1) < bb_lower && iLow(_Symbol, lower_timeframe, 1) < bb_lower2) && PositionSelect(_Symbol) == false && date.hour >= starttime && date.hour <= endtime && allow_bb );
 
  bool div_cond2 = bearish_div_time == zigzagdowntime2 && allow_div && zigzagdown2 == bearish_div_high;
  
  //zz strategy
  zz_dif = zigzagdowntime <= zigzaguptime ? zigzagdown - zigzagup2 : zigzagdown - zigzagup;
  bool cond_44 = ( ((zigzagdowntime <= zigzaguptime && zigzagdown < zigzagdown2 && zigzagup < zigzagup2 && iHigh(_Symbol,lower_timeframe,0) >= zigzagup2) || (zigzagdowntime >= zigzaguptime && iLow(_Symbol, lower_timeframe, 0) < zigzagup && zigzagdown < zigzagdown2 && iHigh(_Symbol,lower_timeframe,0) >= zigzagup) ) && ((allow_div == true && div_cond2) || allow_div == false)); 
  
  bool cond_55 = ( zz_up_time != zigzagdowntime2 && time_of_trade_close <= zigzagdowntime2 && date.hour >= starttime && date.hour < endtime && allow_zz && PositionSelect(_Symbol) == false && 
    ((((zigzagdowntime <= zigzaguptime && zigzagdown <= zigzagup2+percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage)) || (zigzagdowntime >= zigzaguptime && zigzagdown <= zigzagup+percentage_in_pips(zigzagdown2, zigzagup, bo_percentage))) && allow_fib == true) || allow_fib == false) );
  /*((zz_range_high*10)*_Point)>=zz_dif && ((zz_range_low*10)*_Point)<=zz_dif && (nili aunty said that this condition's not needed)*/
  
  bool cond_66 = ( (zigzagdowntime >= zigzaguptime && zigzagdown < zigzagdown2 && iHigh(_Symbol,lower_timeframe,0) >= zigzagup+percentage_in_pips(zigzagdown2, zigzagup, li_percentage)) && allow_fib == true && (div_cond2 || allow_div == false) && PositionSelect(_Symbol) == false && 
    date.hour >= starttime && date.hour < endtime && zz_up_time != zigzagdowntime2 && time_of_trade_close <= zigzagdowntime2 );
  
  //Print(" cond1 = ",zigzagdowntime >= zigzaguptime,"  cond2 = ",zigzagdown < zigzagdown2,"  cond3 = ",iHigh(_Symbol,lower_timeframe,0) >= zigzagdown2-percentage_in_pips(zigzagdown2, zigzagup, li_percentage),"  cond4 = ",allow_fib == true,"");
  //Print(" cond5 = ",(div_cond2 || allow_div == false)," cond6 = ",date.hour >= starttime && date.hour < endtime," cond7 = ",zz_up_time != zigzagdowntime2," cond8 = ",time_of_trade_close <= zigzagdowntime2," ");
  
  if ( (cond_44 && cond_55 && allow_bo_entry) || (cond_66 && allow_limit_entry) )
  {
         double sl2 = 0;
         double tp1 = NormalizeDouble(latest_price.bid - ( zigzagdown2 > latest_price.bid ? (zigzagdown2 - latest_price.bid)*first_trade_exit_ratio : (latest_price.bid - zigzagdown2)*first_trade_exit_ratio ), _Digits);
         double tp2 = NormalizeDouble(latest_price.bid - ( zigzagdown > latest_price.bid ? (zigzagdown - latest_price.bid)*first_trade_exit_ratio : (latest_price.bid - zigzagdown)*first_trade_exit_ratio ), _Digits);
         /*if (  (((((NormalizeDouble(latest_price.bid,_Digits) == NormalizeDouble(zigzagup,_Digits) || (latest_price.bid >= zigzagup-(entryprice_range*10*_Point))) && latest_price.bid < zigzagup)) && (allow_zz == true || (allow_div && allow_zz))) || 
              ((NormalizeDouble(latest_price.bid,_Digits) == NormalizeDouble(iLow(_Symbol, lower_timeframe, 0),_Digits) || (latest_price.bid >= (iLow(_Symbol, lower_timeframe, 0)-(entryprice_range*10*_Point)) && latest_price.bid < iLow(_Symbol, lower_timeframe, 0))) && zigzagdowntime >= zigzaguptime && (allow_zz == true || (allow_div && allow_zz))))   || 
              (((NormalizeDouble(latest_price.bid,_Digits) == NormalizeDouble(iLow(_Symbol, lower_timeframe, 1),_Digits)) || (latest_price.bid >= (iLow(_Symbol, lower_timeframe, 1)-(entryprice_range*10*_Point)) && latest_price.bid < iLow(_Symbol, lower_timeframe, 1)))
              && allow_bb == true)  )(nili aunty said not needed)*/
         if(true)    
         {
         mrequest.action = TRADE_ACTION_DEAL;                                
         mrequest.price = latest_price.bid;
         mrequest.sl = first_trade_exit ? sl2 : 0;
         mrequest.tp = first_trade_exit && cond_66==true ? tp1 : first_trade_exit && cond_55==true && cond_44==true ? tp2 : 0;
         
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); //_Bid
         double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT); //_Point
         double pips = (mrequest.sl > latest_price.bid ? mrequest.sl - latest_price.bid:latest_price.bid - mrequest.sl)/point;
         double freeMargin = AccountInfoDouble(ACCOUNT_EQUITY); //double  AccountFreeMargin();
         double PipValue = ((SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE)*point)/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE)); //MarketInfo(_Symbol, MODE_TICKVALUE)
         double Lots = Risk * freeMargin / (PipValue * pips);
         Lots = floor(Lots * 100) / 100; //MathFloor()
         
         mrequest.symbol = _Symbol;                                         
         mrequest.volume = use_inital_lots == true ? initial_lots:Lots;                                            
         mrequest.magic = 1;                                        
         mrequest.type = ORDER_TYPE_SELL;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;                        
         mrequest.deviation=100;
         
         if( (pip_range(zigzagdown2, mrequest.price)==true && cond_66) || !(cond_66) )
         bool res = OrderSend(mrequest, mresult);
         
         if(mresult.retcode==10009 || mresult.retcode==10008) //Request is completed or order placed
         {
           time_of_trade_open = Bars(_Symbol, lower_timeframe);
           time_of_trade_open2 = iTime(_Symbol, lower_timeframe, 0);
           zz_up_time = zigzagdowntime2;
           trade_check = true;
           low = mrequest.price;
           high =  cond_66 ? zigzagdown2 : cond_44 && cond_55 ? zigzagdown : 0;
           total_mtgl = total_mtgl + ZonePosition.GetMtglCount();
           Alert(" total mtgl sets in ",_Symbol," are " ,total_mtgl, " ");
           Print(" for sell | bo % range of prev leg = ",zigzagup2+percentage_in_pips(zigzagdown2, zigzagup2, bo_percentage),"  limit % range of prev leg = ",zigzagup+percentage_in_pips(zigzagdown2, zigzagup, li_percentage),"  high = ",iHigh(_Symbol,lower_timeframe,0),"  mtgl high = ",high,"");
           //"  100% range for 2nd = ",zigzagdowntime < zigzaguptime ? percentage_in_pips(zigzagdown, zigzagup2, 100):percentage_in_pips(zigzagdown, zigzagup, 100),"");
           
           ulong ticket = 0;
            for(int i = PositionsTotal()-1; i >= 0; i--)
            {
              ticket = PositionGetTicket(i);
              stat_ticket = ticket;
              if(PositionGetString(POSITION_SYMBOL) == _Symbol)
              break;
            }
            
            ZonePosition = new ZPClass((high - low)*risk_reward_tp, high - low, mtgl_multiplier, false, true, false, true, swap, commission);
            ZonePosition.OpenPosition(ticket);
         }
         else
         {
           Print("The sell order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
         }
  }
 
 }
 
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
   
   //Print(profit_total());
   
    
  }
  
  

  
  
bool pip_range(double val1, double val2)
{
  bool check= false;
  if((val1 > val2 ? val1 - val2:val2 - val1) >= max_pips*10*_Point)
  check = true;
  
  return check;
}

double percentage_in_pips(double high_val, double low_val, double percent)
{
  double range = high_val - low_val;
  double per = range * (percent/100);
  
  if(per < 0) per*-1;
  return per;
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
         //trade_close_shift = Bars(symb, lower_timeframe) - 0;
         }
         else
         {
           Print("The closing order request could not be completed -error:",GetLastError());
           ResetLastError();
         }
         }
     }
}

