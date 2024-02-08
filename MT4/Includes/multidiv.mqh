//+------------------------------------------------------------------+
//|                                                     multidiv.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict

#include <extra_fun.mqh>
#include <ObjectFunctions.mqh>

//Description: this mqh file checks for regular & hidden divergence of a particular degree in the specified timeframe and stores specific values in passed variables
//for rsi divergence
static datetime bear_time[]; 
static double bear_val[]; 
static datetime bull_time[]; 
static double bull_val[]; 
static datetime prev_leg1[]; 

//for ao divergence
static datetime ao_bear_time[]; 
static double ao_bear_val[]; 
static datetime ao_bull_time[]; 
static double ao_bull_val[]; 

//+------------------------------------------------------------------+
//|  REGULAR DIVERGENCE                                              |
//+------------------------------------------------------------------+

void regular_divergence(int depth, int deviation, int backstep, ENUM_TIMEFRAMES timeframe, int lookback,
                double& bear_high2, double& bull_low2, datetime& bear_prev_time, datetime& bull_prev_time, datetime& bear_curr_time, datetime&  bull_curr_time, 
                datetime& bull_hp, datetime& bear_lp, int degree, color bear_colour, color bull_colour, int font_s)//the "degree" parameter helps to know which divergence degree we are currently checking
{
  static datetime prev_leg[]; 
  if(ArraySize(prev_leg) == 0) ArrayResize(prev_leg, 6);

  double zigzagup=0;
  double zigzagup2=0;
  double zigzagdown=0;
  double zigzagdown2=0;
  datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
  datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
  int two_up=0,two_down=0,two_up2=0,two_down2=0;
  
  for(int i= 0 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime = iTime(_Symbol,timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         break;
        }
     }
     
   for(int i= 0 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime = iTime(_Symbol,timeframe ,i);
         zigzagup = uparrow;
         two_up = i;
         break;
        }
     }
     
   if(zigzaguptime < zigzagdowntime)  
   {
   for(int i= two_up+1 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         two_up2 = i;
         break;
        }
     }
     
   for(int i=  two_up2+1 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     }
   }
   
   if(zigzaguptime > zigzagdowntime)  
   {  
   for(int i=  two_down+1 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         two_down2 = i;
         break;
        }
     }
     
     for(int i= two_down2+1 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i);
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }
   }
     
  
   if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime)
     { 
         int to = iBarShift(_Symbol,timeframe,zigzaguptime2);
         int from = iBarShift(_Symbol,timeframe,zigzagdowntime2);
         double first_rsi = maxRSIValue(from, to, timeframe);
         datetime first_rsi_time = maxRSITime(from, to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzaguptime);
         int from2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
         double second_rsi = maxRSIValue(from2, to2, timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
         if(first_rsi > second_rsi)
           {
            string name = IntegerToString((long)zigzaguptime2);
            string div_name1 = degree == 1 ? "div1" : degree == 2 ? "div3" : degree == 3 ? "div5" : degree == 4 ? "div7" : degree == 5 ? "div9" : "";
            string div_name2 = degree == 1 ? "div2" : degree == 2 ? "div4" : degree == 3 ? "div6" : degree == 4 ? "div8" : degree == 5 ? "div10" : "";
            string div_label = degree == 1 ? "label1" : degree == 2 ? "label2" : degree == 3 ? "label3" : degree == 4 ? "label4" : degree == 5 ? "label5" : "";
               
            TextDelete(0, div_label);
            TrendDelete(0,div_name1);
            TrendDelete(0,div_name2);
            //Print(div_name2+name);
            
               TextCreate(0, div_label, 0, zigzagdowntime, zigzagdown, "BEAR REG DIV", "Arial", font_s, bear_colour);
               TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,div_name1,bear_colour);
               TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,div_name2,bear_colour);
               
               bear_high2 = zigzagdown; //high_of_reg_bear2
               bear_prev_time = zigzagdowntime2; //reg_bear_div_time
               bear_curr_time = zigzagdowntime; //reg_bear_div_curr_time
               bear_lp = zigzaguptime2; //reg_bear_lp
               
              if(prev_leg[degree] != zigzaguptime2) 
              {
                prev_leg[degree] = zigzaguptime2;
                Alert("Bearish RD in ",_Symbol,"  at ",TimeToString(zigzagdowntime),"");
              }
           }
     }
     
     if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2)
     {
     
            int to = iBarShift(_Symbol,timeframe,zigzagdowntime2);
            int from = iBarShift(_Symbol,timeframe,zigzaguptime2);
            double first_rsi = minRSIValue(from, to, timeframe);
            datetime first_rsi_time = minRSITime(from, to, timeframe);
            int to2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
            int from2 = iBarShift(_Symbol,timeframe,zigzaguptime);
            double second_rsi = minRSIValue(from2, to2, timeframe);
            datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
            if(first_rsi < second_rsi)
              {
               string name = IntegerToString((long)zigzagdowntime2);
               string div_name1 = degree == 1 ? "div1" : degree == 2 ? "div3" : degree == 3 ? "div5" : degree == 4 ? "div7" : degree == 5 ? "div9" : "";
               string div_name2 = degree == 1 ? "div2" : degree == 2 ? "div4" : degree == 3 ? "div6" : degree == 4 ? "div8" : degree == 5 ? "div10" : "";
               string div_label = degree == 1 ? "label1" : degree == 2 ? "label2" : degree == 3 ? "label3" : degree == 4 ? "label4" : degree == 5 ? "label5" : "";
               
               TextDelete(0, div_label);
               TrendDelete(0,div_name1);
               TrendDelete(0,div_name2);
               
               //ObjectCreate(0, "label", OBJ_TEXT, 0, zigzaguptime, zigzagup);
               //ObjectSetText("label", "BRD", 20, NULL, bull_colour);
               TextCreate(0, div_label, 0, zigzaguptime, zigzagup, "BULL REG DIV", "Arial", font_s, bull_colour);
               TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,div_name1,bull_colour);
               TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,div_name2,bull_colour);
              
               bull_low2 = zigzagup; //low_of_reg_bull2
               bull_prev_time = zigzaguptime2; //reg_bull_div_time
               bull_curr_time = zigzaguptime; //reg_bull_div_curr_time
               bull_hp = zigzagdowntime2; //reg_bull_lp
               
              if(prev_leg[degree] != zigzagdowntime2) 
              {
                prev_leg[degree] = zigzagdowntime2;
                Alert("Bullish RD in ",_Symbol,"  at ",TimeToString(zigzaguptime),"");
              }
              }
     }
}



//+------------------------------------------------------------------+
//|  HIDDEN DIVERGENCE                                               |
//+------------------------------------------------------------------+

void hidden_divergence(int depth, int deviation, int backstep, ENUM_TIMEFRAMES timeframe,int lookback,
                double& bear_high2, double& bull_low2, double& bear_high, double& bull_low, datetime& bear_prev_time, datetime& bull_prev_time, 
                datetime& bear_curr_time, datetime& bull_curr_time, datetime& bull_hp, datetime& bear_lp, int degree, color bear_colour, color bull_colour, int font_s)
{
  static datetime prev_leg[]; 
  if(ArraySize(prev_leg) == 0) ArrayResize(prev_leg, 6);
   
   double zigzagup=0;
  double zigzagup2=0;
  double zigzagdown=0;
  double zigzagdown2=0;
  datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
  datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
  int two_up=0,two_down=0,two_up2=0,two_down2=0;
  
  for(int i= 0 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime = iTime(_Symbol,timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         break;
        }
     }
     
   for(int i= 0 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime = iTime(_Symbol,timeframe ,i);
         zigzagup = uparrow;
         two_up = i;
         break;
        }
     }
     
   if(zigzaguptime < zigzagdowntime)  
   {
   for(int i= two_up+1 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         two_up2 = i;
         break;
        }
     }
     
   for(int i=  two_up2+1 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     }
   }
   
   if(zigzaguptime > zigzagdowntime)  
   {  
   for(int i=  two_down+1 ; i<lookback; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         two_down2 = i;
         break;
        }
     }
     
     for(int i= two_down2+1 ; i<lookback; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i);
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }
   }
     
  
   if(zigzagdown < zigzagdown2  && zigzaguptime < zigzagdowntime) //hidden bearish
   {
         int to = iBarShift(_Symbol,timeframe,zigzaguptime2);
         int from = iBarShift(_Symbol,timeframe,zigzagdowntime2);
         double first_rsi = maxRSIValue(from , to, timeframe);
         datetime first_rsi_time = maxRSITime(from , to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzaguptime);
         int from2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
         double second_rsi = maxRSIValue(from2 , to2, timeframe);
         datetime second_rsi_time = maxRSITime(from2 , to2, timeframe);
         if(first_rsi < second_rsi)
         {
               string name = IntegerToString((long)zigzaguptime2);
               string div_name1 = degree == 1 ? "hiddiv1" : degree == 2 ? "hiddiv3" : degree == 3 ? "hiddiv5" : degree == 4 ? "hiddiv7" : degree == 5 ? "hiddiv9" : "";
               string div_name2 = degree == 1 ? "hiddiv2" : degree == 2 ? "hiddiv4" : degree == 3 ? "hiddiv6" : degree == 4 ? "hiddiv8" : degree == 5 ? "hiddiv10" : "";
               string div_label = degree == 1 ? "hidlabel1" : degree == 2 ? "hidlabel2" : degree == 3 ? "hidlabel3" : degree == 4 ? "hidlabel4" : degree == 5 ? "hidlabel5" : "";
                  
               TextDelete(0, div_label);
               TrendDelete(0,div_name1);
               TrendDelete(0,div_name2);
   
               TextCreate(0, div_label, 0, zigzagdowntime2, zigzagdown2, "BEAR HID DIV", "Arial", font_s, bear_colour);
               TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,div_name1,bear_colour);  
               TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,div_name2,bear_colour);  
             
               bear_prev_time = zigzagdowntime2; //hid_bear_div_time
               bear_curr_time = zigzagdowntime; //hid_bear_div_curr_time
               bear_high = zigzagdown2; //high_of_hid_bear
               bear_high2 = zigzagdown; //high_of_hid_bear2
               bear_lp = zigzaguptime2;
               
              if(prev_leg[degree] != zigzaguptime2) 
              {
                prev_leg[degree] = zigzaguptime2;
                Alert("Bearish HD in ",_Symbol,"  at ",TimeToString(zigzagdowntime),"");
              }
         }
   }
   
   if(zigzaguptime > zigzagdowntime && zigzagup > zigzagup2) //hidden bullish
   {
         int to = iBarShift(_Symbol,timeframe,zigzagdowntime2);
         int from = iBarShift(_Symbol,timeframe,zigzaguptime2);
         double first_rsi = minRSIValue(from , to, timeframe);
         datetime first_rsi_time = minRSITime(from , to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
         int from2 = iBarShift(_Symbol,timeframe,zigzaguptime);
         double second_rsi = minRSIValue(from2 , to2, timeframe);
         datetime second_rsi_time = minRSITime(from2 , to2, timeframe);
         if(first_rsi > second_rsi)
         {
               string name = IntegerToString((long)zigzagdowntime2);
               string div_name1 = degree == 1 ? "hiddiv1" : degree == 2 ? "hiddiv3" : degree == 3 ? "hiddiv5" : degree == 4 ? "hiddiv7" : degree == 5 ? "hiddiv9" : "";
               string div_name2 = degree == 1 ? "hiddiv2" : degree == 2 ? "hiddiv4" : degree == 3 ? "hiddiv6" : degree == 4 ? "hiddiv8" : degree == 5 ? "hiddiv10" : "";
               string div_label = degree == 1 ? "hidlabel1" : degree == 2 ? "hidlabel2" : degree == 3 ? "hidlabel3" : degree == 4 ? "hidlabel4" : degree == 5 ? "hidlabel5" : "";
               
               TextDelete(0, div_label);
               TrendDelete(0,div_name1);
               TrendDelete(0,div_name2);
               
               TextCreate(0, div_label, 0, zigzaguptime2, zigzagup2, "BULL HID DIV", "Arial", font_s, bull_colour);
               TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,div_name1,bull_colour);  
               TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,div_name2,bull_colour);     
           
               bull_prev_time = zigzaguptime2; //hid_bull_div_time
               bull_curr_time = zigzaguptime; //hid_bull_div_curr_time
               bull_low = zigzagup2; //low_of_hid_bull
               bull_low2 = zigzagup; //low_of_hid_bull2
               bull_hp = zigzagdowntime2;
               
              if(prev_leg[degree] != zigzagdowntime2) 
              {
                prev_leg[degree] = zigzagdowntime2;
                Alert("Bullish HD in ",_Symbol,"  at ",TimeToString(zigzaguptime),"");
              }
         }
   }
}


//+------------------------------------------------------------------+
//|  REGULAR DIVERGENCE                                              | 
//+------------------------------------------------------------------+

//this looks for divergences from a certain point in time
//this function is for waverunner_netting ea

void divergence(int depth, int deviation, int backstep, ENUM_TIMEFRAMES timeframe, int lookback, int start_shift,
                double& bear_high2, double& bull_low2, datetime& bear_curr_time, datetime&  bull_curr_time, 
                int degree, color bear_colour, color bull_colour, int font_s)//the "degree" parameter helps to know which divergence degree we are currently checking
{
  if(ArraySize(bear_val) == 0) ArrayResize(bear_val, 6);
  if(ArraySize(bear_time) == 0) ArrayResize(bear_time, 6);
  
  if(ArraySize(bull_val) == 0) ArrayResize(bull_val, 6);
  if(ArraySize(bull_time) == 0) ArrayResize(bull_time, 6);
  
  if(ArraySize(prev_leg1) == 0) ArrayResize(prev_leg1, 6);

  double zigzagup=0;
  double zigzagup2=0;
  double zigzagdown=0;
  double zigzagdown2=0;
  datetime zigzagdowntime=NULL,zigzagdowntime2=NULL;
  datetime zigzaguptime = NULL,zigzaguptime2 = NULL;
  int two_up=0,two_down=0,two_up2=0,two_down2=0;
  int _end = start_shift + lookback;
  
  for(int i= start_shift; i<_end; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime = iTime(_Symbol,timeframe,i);
         zigzagdown = downarrow;
         two_down = i;
         break;
        }
     }
     
   for(int i= start_shift; i<_end; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime = iTime(_Symbol,timeframe ,i);
         zigzagup = uparrow;
         two_up = i;
         break;
        }
     }
     
   if(zigzaguptime < zigzagdowntime)  
   {
   _end = two_up + lookback;
   for(int i= two_up; i<_end; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i); //up val
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         two_up2 = i;
         break;
        }
     }
     
     _end = two_up2 + lookback;
   for(int i=  two_up2; i<_end; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         break;
        }
     }
   }
   
   if(zigzaguptime > zigzagdowntime)  
   {  
   _end = two_down + lookback;
   for(int i=  two_down; i<_end; i++)
     {
      double uparrow=iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 2, i);
      if(uparrow>0 && uparrow != EMPTY_VALUE)
        {
         zigzaguptime2 = iTime(_Symbol,timeframe,i);
         zigzagup2 = uparrow;
         two_down2 = i;
         break;
        }
     }
     
     _end = two_down2 + lookback;
     for(int i= two_down2; i<_end; i++)
     {
      double downarrow= iCustom(_Symbol,timeframe,"WaveRunnerConfirm",depth,deviation,backstep, 3, i);
      if(downarrow>0 && downarrow != EMPTY_VALUE)
        {
         zigzagdowntime2 = iTime(_Symbol,timeframe,i);
         zigzagdown2 = downarrow;
         break;
        }
     }
   }
     
 
     if(zigzagdown > zigzagdown2 && zigzagup > zigzagup2 && zigzaguptime < zigzagdowntime)
     { 
         int to = iBarShift(_Symbol,timeframe,zigzaguptime2);
         int from = iBarShift(_Symbol,timeframe,zigzagdowntime2);
         double first_rsi = maxRSIValue(from, to, timeframe);
         datetime first_rsi_time = maxRSITime(from, to, timeframe);
         int to2 = iBarShift(_Symbol,timeframe,zigzaguptime);
         int from2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
         double second_rsi = maxRSIValue(from2, to2, timeframe);
         datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
         if(first_rsi > second_rsi)
           {
            string name = IntegerToString((long)zigzaguptime2);
            string div_name1 = degree == 1 ? "div1" : degree == 2 ? "div3" : degree == 3 ? "div5" : degree == 4 ? "div7" : degree == 5 ? "div9" : "";
            string div_name2 = degree == 1 ? "div2" : degree == 2 ? "div4" : degree == 3 ? "div6" : degree == 4 ? "div8" : degree == 5 ? "div10" : "";
            string div_label = degree == 1 ? "label1" : degree == 2 ? "label2" : degree == 3 ? "label3" : degree == 4 ? "label4" : degree == 5 ? "label5" : "";
               
            TextDelete(0, div_label);
            TrendDelete(0,div_name1);
            TrendDelete(0,div_name2);
            //Print(div_name2+name);
            
               TextCreate(0, div_label, 0, zigzagdowntime, zigzagdown, "BEAR REG DIV", "Arial", font_s, bear_colour);
               TrendCreate(zigzaguptime2,zigzagup2,zigzagdowntime2,zigzagdown2,div_name1,bear_colour);
               TrendCreate(zigzaguptime,zigzagup,zigzagdowntime,zigzagdown,div_name2,bear_colour);
               
               bear_high2 = zigzagdown;
               bear_curr_time = zigzagdowntime;
               bear_val[degree] = zigzagdown;
               bear_time[degree] = zigzagdowntime;
               
              if(prev_leg1[degree] != zigzaguptime2) 
              {
                prev_leg1[degree] = zigzaguptime2;
                Alert("Bearish RD in ",_Symbol,"  at ",TimeToString(zigzagdowntime),"");
              }
           }
     }

     
     
     if(zigzaguptime > zigzagdowntime && zigzagup < zigzagup2 && zigzagdown < zigzagdown2)
     {
            int to = iBarShift(_Symbol,timeframe,zigzagdowntime2);
            int from = iBarShift(_Symbol,timeframe,zigzaguptime2);
            double first_rsi = minRSIValue(from, to, timeframe);
            datetime first_rsi_time = minRSITime(from, to, timeframe);
            int to2 = iBarShift(_Symbol,timeframe,zigzagdowntime);
            int from2 = iBarShift(_Symbol,timeframe,zigzaguptime);
            double second_rsi = minRSIValue(from2, to2, timeframe);
            datetime second_rsi_time = maxRSITime(from2, to2, timeframe);
            if(first_rsi < second_rsi)
              {
               string name = IntegerToString((long)zigzagdowntime2);
               string div_name1 = degree == 1 ? "div1" : degree == 2 ? "div3" : degree == 3 ? "div5" : degree == 4 ? "div7" : degree == 5 ? "div9" : "";
               string div_name2 = degree == 1 ? "div2" : degree == 2 ? "div4" : degree == 3 ? "div6" : degree == 4 ? "div8" : degree == 5 ? "div10" : "";
               string div_label = degree == 1 ? "label1" : degree == 2 ? "label2" : degree == 3 ? "label3" : degree == 4 ? "label4" : degree == 5 ? "label5" : "";
               
               TextDelete(0, div_label);
               TrendDelete(0,div_name1);
               TrendDelete(0,div_name2);
               
               TextCreate(0, div_label, 0, zigzaguptime, zigzagup, "BULL REG DIV", "Arial", font_s, bull_colour);
               TrendCreate(zigzagdowntime2,zigzagdown2,zigzaguptime2,zigzagup2,div_name1,bull_colour);
               TrendCreate(zigzagdowntime,zigzagdown,zigzaguptime,zigzagup,div_name2,bull_colour);
              
               bull_low2 = zigzagup;
               bull_curr_time = zigzaguptime;
               bull_val[degree] = zigzagup;
               bull_time[degree] = zigzaguptime;
               
              if(prev_leg1[degree] != zigzagdowntime2) 
              {
                prev_leg1[degree] = zigzagdowntime2;
                Alert("Bullish RD in ",_Symbol,"  at ",TimeToString(zigzaguptime),"");
              }
              }
     }
  
}



//+------------------------------------------------------------------+
//| AO DIVERGENCE                                                    |
//+------------------------------------------------------------------+

void ao_divergence(ENUM_TIMEFRAMES timeframe, int lookback, int start_shift, int degree,
                  color _UP_C1, color _UP_M1, color _UP_M5, color _UP_M15, color _UP_M30, color _UP_H1, color _UP_H4, color _UP_D1, color _UP_W1, color _UP_MN1, 
                  color _DOWN_C1, color _DOWN_M1, color _DOWN_M5, color _DOWN_M15, color _DOWN_M30, color _DOWN_H1, color _DOWN_H4, color _DOWN_D1, color _DOWN_W1, color _DOWN_MN1,
                  int depth, int deviation, int backstep)//the "degree" parameter helps to know which divergence degree we are currently checking
{
  if(ArraySize(ao_bear_val) == 0) ArrayResize(ao_bear_val, 1);
  if(ArraySize(ao_bear_time) == 0) ArrayResize(ao_bear_time, 1);
  
  if(ArraySize(ao_bull_val) == 0) ArrayResize(ao_bull_val, 1);
  if(ArraySize(ao_bull_time) == 0) ArrayResize(ao_bull_time, 1);
  
   double low=0, high=0;
   int _end = start_shift+lookback;
   for(int j = start_shift; j < _end; j++) //for buy ao div
    {
       double ao_div1 = iCustom(_Symbol, timeframe, "AO_DIV_Waverunr", _UP_C1, _UP_M1, _UP_M5, _UP_M15, _UP_M30, _UP_H1, _UP_H4, _UP_D1, _UP_W1, _UP_MN1, _DOWN_C1, _DOWN_M1, _DOWN_M5, _DOWN_M15, _DOWN_M30, _DOWN_H1, _DOWN_H4, _DOWN_D1, _DOWN_W1, _DOWN_MN1, depth, deviation, backstep, 1, j);
       double ao_div3 = iCustom(_Symbol, timeframe, "AO_DIV_Waverunr", _UP_C1, _UP_M1, _UP_M5, _UP_M15, _UP_M30, _UP_H1, _UP_H4, _UP_D1, _UP_W1, _UP_MN1, _DOWN_C1, _DOWN_M1, _DOWN_M5, _DOWN_M15, _DOWN_M30, _DOWN_H1, _DOWN_H4, _DOWN_D1, _DOWN_W1, _DOWN_MN1, depth, deviation, backstep, 3, j);
      
       if(ao_div1 != EMPTY_VALUE && low == 0)
       {
         ao_bull_time[0] = iTime(_Symbol, timeframe, j);
         ao_bull_val[0] = ao_div1;
         low = ao_div1;
       }
       
       if(ao_div3 != EMPTY_VALUE && high == 0)
       {
         ao_bear_time[0] = iTime(_Symbol, timeframe, j);
         ao_bear_val[0] = ao_div3;
         high = ao_div1;
       }
    }
}

  
double maxRSIValue(int from, int to, ENUM_TIMEFRAMES tf)
  {
   double max_first_rsi=0;
   for(int i = from ; i<=to; i++)
     {
      double rsi = iRSI(_Symbol,tf,14,PRICE_CLOSE,i);
      if(max_first_rsi < rsi)
         max_first_rsi = rsi;
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
   for(int i = from ; i<=to; i++)
     {
      double rsi = iRSI(_Symbol,tf,14,PRICE_CLOSE,i);
      if(max_first_rsi < rsi)
        {
         max_first_rsi = rsi;
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
   for(int i = from ; i<=to; i++)
     {
      double rsi =  iRSI(_Symbol,tf,14,PRICE_CLOSE,i);
      if(min_first_rsi > rsi)
         min_first_rsi = rsi;
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
   for(int i = from ; i<=to; i++)
     {
      double rsi = iRSI(_Symbol,tf,14,PRICE_CLOSE,i);
      if(min_first_rsi > rsi)
        {
         min_first_rsi = rsi;
         mintime = iTime(_Symbol,tf,i);
        }
     }
   return mintime;
  }
  
