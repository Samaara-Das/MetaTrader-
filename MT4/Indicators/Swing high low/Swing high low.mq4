//+------------------------------------------------------------------+
//|                                               Swing high low.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright 
#property link      
#property version   "2.00"
#property strict
#property indicator_chart_window
#property description            "The swings are drawn in AO red or green ranges (regardless of negative or positive ranges). The highs are drawn when the AO is green & the lows are drawn when the AO is red."
#property description            "If the lines are haywire and are not being drawn correctly, re-compile the indicator or remove it & put it back on the chart or just switch the timeframe."
#property indicator_buffers      3        // Number of buffers
#define   DATA_LIMIT             34       // Bars minimum for calculation

#include <ObjectFunctions.mqh>


// Global Variables
double lowestLowVal = 0, highestHighVal = 0;       // for tracking the lowest/highest bar's price 
int positiveRangeBar = 0, negativeRangeBar = 0;    // for tracking the start of an ao range
double count = 0;                                  // for adding number identifiers to the line name
int highShift = 0, lowShift = 0;

// Buffers 
double arrowHigh[], arrowLow[], arrowExt[];     
 


int OnInit()
{
   
   // Setting up arrow buffers
   //SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 2, clrLime); 
   //SetIndexArrow(0, 233);
   SetIndexBuffer(0, arrowHigh);        
   SetIndexLabel(0, "Arrow High");
   
   //SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, clrRed); 
   //SetIndexArrow(1, 234);
   SetIndexBuffer(1, arrowLow);        
   SetIndexLabel(1, "Arrow Low");
   
   SetIndexBuffer(2, arrowExt);
   SetIndexStyle(2, DRAW_SECTION, STYLE_SOLID, 2, clrCornflowerBlue);           
   SetIndexLabel(2, "Arrow Ext");
   
   IndicatorDigits(5);
   
   return(INIT_SUCCEEDED);
}
  
  
  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int Counted_bars  =  IndicatorCounted();        
   int bars          =  iBars(_Symbol, _Period);
   int j             =  bars-Counted_bars-1; 
   
   // Check if we have enough bars on the chart
   if(bars<=DATA_LIMIT) return(0);
      
   // Loop for uncounted bars & for the 0th bar
   while(j >= 0)                   
   {
      int shift1 = j+1;
      int shift2 = j+2;
      int shift3 = j+3;
      
      double ao1 = iAO(_Symbol, _Period, shift1);
      double ao2 = iAO(_Symbol, _Period, shift2);
      double ao3 = iAO(_Symbol, _Period, shift3);
      
      bool isGreen = ao2 < ao1;
      bool isRed = ao2 > ao1;
      bool isPrevGreen = ao3 < ao2;
      bool isPrevRed = ao3 > ao2;
   
      // mark the start of a new range
      if(isRed && isPrevGreen)
      {
         lowestLowVal      = low[shift1];
         arrowLow[shift1]  = lowestLowVal;
         arrowExt[shift1]  = arrowLow[shift1];
         lowShift          = bars - shift1;
      }
      
      if(isGreen && isPrevRed)
      {
         highestHighVal    = high[shift1];
         arrowHigh[shift1] = highestHighVal;
         arrowExt[shift1]  = arrowHigh[shift1];
         highShift         = bars - shift1;
      }
      
      
      
      // update the highest high/lowest low
      if(isGreen)
      {
         double _high = high[shift1];
         if(_high > highestHighVal)
         {
            highestHighVal    = _high;
            int shift = bars - highShift;
            
            // To only show the most latest high and not the older ones
            if(highShift != 0)
            {
               arrowHigh[shift] = EMPTY_VALUE;
               arrowExt[shift]  = arrowHigh[shift];
            }
               
            arrowHigh[shift1] = highestHighVal;
            arrowExt[shift1]  = arrowHigh[shift1];
            highShift         = bars - shift1;
         }
      }
      
      if(isRed)
      {
         double _low = low[shift1];
         if(_low < lowestLowVal)
         {
            lowestLowVal     = _low;
            int shift = bars - lowShift;
            
            // To only show the most latest low and not the older ones
            if(lowShift != 0)
            {
               arrowLow[shift] = EMPTY_VALUE;
               arrowExt[shift] = arrowLow[shift];
            }
               
            arrowLow[shift1] = lowestLowVal;
            arrowExt[shift1] = arrowLow[shift1];
            lowShift         = bars - shift1;
         }
      }  
       
      j--;  
   }
   

   return(rates_total);
}


