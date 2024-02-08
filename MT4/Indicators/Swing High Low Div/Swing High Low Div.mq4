//+------------------------------------------------------------------+
//|                                           Swing High Low Div.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright 
#property link      
#property version   "1.00"
#property strict
#property indicator_chart_window
#property description            "This is draws Hidden & Regular divergence based on the Swing high low indicator. One problem its facing is that the rectangles don't get deleted."
#property indicator_buffers      5        // Number of buffers
#define   SWING_INDICATOR        
#define   FIB_NAME               "Fib"

#include <ObjectFunctions.mqh>
#include <Fibonacci.mqh>

// Inputs
//input string InpSwingIndPath      = "Swing high low"; // Path of Swing High Low indicator
input string InpSwingIndPath      = "\\Swing High Low\\Swing high low"; // Path of Swing High Low indicator
input bool   InpDrawRegDiv        = True;         // Draw Regular Divergence
input bool   InpDrawHidDiv        = True;         // Draw Hidden Divergence
input bool   InpDrawFib           = True;         // Draw Fib
input bool   InpDrawRsiShading    = True;         // Draw Rsi Shading
input color  regBearColour        = clrRed;       // Reg Bear 
input color  regBullColour        = clrLime;      // Reg Bull 
input color  hidBearColour        = clrMaroon;    // Hid Bear 
input color  hidBullColour        = clrGreen;     // Hid Bull 
input double InpRsiOb             = 60;           // RSI Overbought Level
input double InpRsiOs             = 40;           // RSI Oversold Level
input int    InpRsiPeriod         = 14;           // RSI Period
input ENUM_APPLIED_PRICE InpRsiApplied  = PRICE_CLOSE; // RSI Applied Price
input color  InpBearColour        = C'36,0,0';    // RSI Bear Shading
input color  InpBullColour        = C'0,32,0';    // RSI Bull Shading



// Global Variables
double lowestLowVal = 0, highestHighVal = 0;                // Tracking the lowest/highest bar's price 
double prevLowestLowVal = 0, prevHighestHighVal = 0;        // Tracking the previous lowest/highest bar's price 
int    lowestLowBar = 0, highestHighBar = 0;                // Tracking the lowest/highest bar's bar 
int    prevLowestLowBar = 0, prevHighestHighBar = 0;        // Tracking the previous lowest/highest bar's bar 

int      _count = 0, recCount = 0;                          // Adding number identifiers to objects
string   currDivName = "";                                  // Name of latest drawn divergence
datetime timeOfPrevDiv = 0;                                 // Time of the furthest part of a divegence

string recNames[];                                          // To keep track of rectangle names so that they can be deleted


// Arrays for our buffers
double arrowHigh[], arrowLow[];   
double prevArrowHigh[], prevArrowLow[];    
double divBuffer[];




void OnDeinit(const int reason)
{
   // Delete all divergence lines drawn by the indicator
   bool divResult = True;
   
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
      divResult &= ObjectDelete(ObjectName(i));
      
   if(divResult) Print("Divergence lines deleted successfully!");
   else          Print("Could not delete lines. Error: ", GetLastError());
      
      
   // Delete all the rectangles
   bool recResult = True;
   int size = ArraySize(recNames);
   
   if(size > 0)
   {
      for(int i = size - 1; i >= 0; i--)
         recResult &= ObjectDelete(recNames[i]);
   }
   
   if(recResult) Print("Rectangles deleted successfully!");
   else          Print("Could not delete rectangles. Error: ", GetLastError());
   
}

int OnInit()
{
   
   // Setting up latest arrow buffers
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 2, clrLime); 
   SetIndexArrow(0, 233);
   SetIndexBuffer(0, arrowHigh);        
   SetIndexLabel(0, "Arrow High");
   
   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, clrRed); 
   SetIndexArrow(1, 234);
   SetIndexBuffer(1, arrowLow);        
   SetIndexLabel(1, "Arrow Low");
   
   // Setting up previous arrow buffers
   SetIndexBuffer(2, prevArrowHigh);        
   SetIndexLabel(2, "Prev Arrow High");
   
   SetIndexBuffer(3, prevArrowLow);        
   SetIndexLabel(3, "Prev Arrow Low");
   
   // Divergence buffer (1 - regular bull, 2 - regular bear, 3 - hidden bull, 4 - hidden bear)
   SetIndexBuffer(4, divBuffer);        
   SetIndexLabel(4, "Divergence");
   
   
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
   int Counted_bars  =  IndicatorCounted();        // Number of counted bars
   int bars          =  iBars(_Symbol, _Period);
   int i             =  bars-Counted_bars-1; 
   
   
   // Setup
   if(rates_total<=34)
      return(0);
      
      
   // Loop for uncounted bars & for the 0th bar
   while(i >= 0)                   
   {
      int shift1 = i+1;
      int shift = i+1;
      if(shift > bars-1) shift = bars-1;
      divBuffer[shift] = 0;  // Setting the default initial value
      
      // get the latest lows & highs
      arrowHigh[shift] = iCustom(_Symbol, _Period, InpSwingIndPath, 0, shift1);
      arrowLow[shift] = iCustom(_Symbol, _Period, InpSwingIndPath, 1, shift1);     
      
      // get the previous high
      if(arrowHigh[shift] != EMPTY_VALUE)
      {
         highestHighVal = arrowHigh[shift];
         highestHighBar = bars - shift;
         prevArrowHigh[shift] = GetPrevArrow(0, shift1, prevHighestHighVal, prevHighestHighBar);
      }
     
      // get the previous low
      if(arrowLow[shift] != EMPTY_VALUE)
      {
         lowestLowVal = arrowLow[shift];
         lowestLowBar = bars - shift;
         prevArrowLow[shift] = GetPrevArrow(1, shift1, prevLowestLowVal, prevLowestLowBar);
      }
 
      //high & low time variables
      datetime prevHighestHighTime = iTime(_Symbol, _Period, bars - prevHighestHighBar);
      datetime prevLowestLowTime = iTime(_Symbol, _Period, bars - prevLowestLowBar);
      datetime highestHighTime = iTime(_Symbol, _Period, bars - highestHighBar);
      datetime lowestLowTime = iTime(_Symbol, _Period, bars - lowestLowBar);
      
      // Draw Fibo
      if(InpDrawFib)
         DrawFib(highestHighTime, lowestLowTime, lowestLowVal, highestHighVal);
      
      //Draw Rsi Shadings
      if(InpDrawRsiShading)
         DrawRsiShading(shift);
      
      //Draw Reg Divergence
      if(InpDrawRegDiv)
      {
         // Logic for bull regular divergence
         if(arrowLow[shift] != EMPTY_VALUE && prevLowestLowVal > lowestLowVal && prevHighestHighVal > highestHighVal)
         {
            double first_ao = minAOValue(bars - prevHighestHighBar, bars - prevLowestLowBar, _Period);
            double second_ao = minAOValue(bars - highestHighBar, bars - lowestLowBar, _Period);
            
            if(first_ao < second_ao)
               ManageBullTrendlines(prevLowestLowTime, lowestLowTime, shift, 1, "regbull ", regBullColour);
         }
      
         // Logic for bear regular divergence
         if(arrowHigh[shift] != EMPTY_VALUE && prevLowestLowVal < lowestLowVal && prevHighestHighVal < highestHighVal)
         {
            double first_ao = maxAOValue(bars - prevLowestLowBar, bars - prevHighestHighBar, _Period);
            double second_ao = maxAOValue(bars - lowestLowBar, bars - highestHighBar, _Period);
            
            if(first_ao > second_ao)
               ManageBearTrendlines(prevHighestHighTime, highestHighTime, shift, 2, "regbear ", regBearColour);
         }
         
      }
       
      //Draw Hid Divergence
      if(InpDrawHidDiv)
      {
         // Logic for bull hidden divergence
         if(arrowLow[shift] != EMPTY_VALUE && prevLowestLowVal < lowestLowVal && prevHighestHighVal > highestHighVal)
         {
            double first_ao = minAOValue(bars - prevHighestHighBar, bars - prevLowestLowBar, _Period);
            double second_ao = minAOValue(bars - highestHighBar, bars - lowestLowBar, _Period);
            
            if(first_ao > second_ao)
               ManageBullTrendlines(prevLowestLowTime, lowestLowTime, shift, 3, "hidbull ", hidBullColour);
            
         }
         
         // Logic for bear hidden divergence
         if(arrowHigh[shift] != EMPTY_VALUE && prevLowestLowVal < lowestLowVal && prevHighestHighVal > highestHighVal)
         {
            double first_ao = maxAOValue(bars - prevLowestLowBar, bars - prevHighestHighBar, _Period);
            double second_ao = maxAOValue(bars - lowestLowBar, bars - highestHighBar, _Period);
            
            if(first_ao < second_ao)
               ManageBearTrendlines(prevHighestHighTime, highestHighTime, shift, 4, "hidbear ", hidBearColour);
         }
      }
     
      
      i--;                        
   }
   

   return(rates_total);
}




//------------------------------------------------------------------------------------
bool DrawFib(datetime _highestHighTime, datetime _lowestLowTime, double _lowestLowVal, double _highestHighVal)
{
   bool result = false;
   
   if(_highestHighTime > _lowestLowTime)
      result = DrawFibo(FIB_NAME, _lowestLowTime, _lowestLowVal, _highestHighTime, _highestHighVal);
   else
      result = DrawFibo(FIB_NAME, _highestHighTime, _highestHighVal, _lowestLowTime, _lowestLowVal);
   
   Sleep(100);
   return(result);
}



//------------------------------------------------------------------------------------
bool DrawRsiShading(int shift)
{
   bool result = false;
   double rsi = iRSI(_Symbol, _Period, InpRsiPeriod, InpRsiApplied, shift);
   datetime time1 = iTime(_Symbol, _Period, shift);
   datetime time2 = iTime(_Symbol, _Period, shift+1);
   
   if(rsi >= InpRsiOb)
   {
      recCount++;
      string name = IntegerToString(recCount)+" Rec";
      result = RectangleCreate(0, name, 0, time1, FLT_MIN, time2, INT_MAX, InpBullColour);
      if(result) addRecName(name);
   }
   
   if(rsi <= InpRsiOs)
   {
      recCount++;
      string name = IntegerToString(recCount)+" Rec";
      result = RectangleCreate(0, name, 0, time1, FLT_MIN, time2, INT_MAX, InpBearColour);
      if(result) addRecName(name);
   }
   
   return(result);
}



//------------------------------------------------------------------------------------
void ManageBullTrendlines(datetime _prevLowestLowTime, datetime _lowestLowTime, int _shift, int buffVal, string name, color colour)
{
   // create new divergence trendlines
   if(timeOfPrevDiv != _prevLowestLowTime)
   {
      TrendSelectionChange(0, currDivName); // unselect the last div line
      timeOfPrevDiv = _prevLowestLowTime;
      divBuffer[_shift] = buffVal;
      _count++;
      currDivName = name+IntegerToString(_count);
      TrendCreate(_prevLowestLowTime, prevLowestLowVal, _lowestLowTime, lowestLowVal, currDivName, colour);
   }
   else // modify divergence trendlines
      TrendPointChange(0, currDivName, 1, _lowestLowTime, lowestLowVal);
}



//------------------------------------------------------------------------------------
void ManageBearTrendlines(datetime _prevHighestHighTime, datetime _highestHighTime, int _shift, int buffVal, string name, color colour)
{
   // create new divergence trendlines
   if(timeOfPrevDiv != _prevHighestHighTime)
   {
      TrendSelectionChange(0, currDivName); // unselect the last div line
      timeOfPrevDiv = _prevHighestHighTime;
      divBuffer[_shift] = buffVal;
      _count++;
      currDivName = name+IntegerToString(_count);
      TrendCreate(_prevHighestHighTime, prevHighestHighVal, _highestHighTime, highestHighVal, currDivName, colour);
   }
   else // modify divergence trendlines
      TrendPointChange(0, currDivName, 1, _highestHighTime, highestHighVal);
}



//------------------------------------------------------------------------------------
double GetPrevArrow(int buff, int shift1, double& prevExtremeVal, int& prevExtremeBar)
{
   int endShift = shift1 + 1 + 200;
   int bars = iBars(_Symbol, _Period);
   if(endShift > bars-1) endShift = bars-1; // if the end shift is ending at a bar which exceeds the bars on the chart, change it
   
   for(int j = shift1+1; j <= endShift; j++)
   {
      double val = iCustom(_Symbol, _Period, InpSwingIndPath, buff, j);
      if(val != EMPTY_VALUE)
      {
         prevExtremeVal = val;
         prevExtremeBar = bars - j;
         return val;
      }
   }
   
   return EMPTY_VALUE;
}


//------------------------------------------------------------------------------------
void addRecName(string name)
{
    // First, find the current size of the "recNames" array
    int currentSize = ArraySize(recNames);

    // Resize the array to accommodate one more element
    ArrayResize(recNames, currentSize + 1);

    // Change the newly added element to the provided "name"
    recNames[currentSize] = name;
}



//------------------------------------------------------------------------------------
double maxAOValue(int from, int to, int tf)
{
   double max_ao = 0;
   int startShift = from <= to ? from : to;
   int endShift = to > from ? to : from;
   for(int i = startShift; i <= endShift; i++)
   {
      double ao = iAO(_Symbol, tf, i);
      if(max_ao < ao)
         max_ao = ao;
   }
     
   return max_ao;
}



//------------------------------------------------------------------------------------
double minAOValue(int from, int to, int tf)
{
   double min_ao = iAO(_Symbol, tf, from);
   int startShift = from <= to ? from : to;
   int endShift = to > from ? to : from;
   for(int i = startShift; i <= endShift; i++)
   {
      double ao = iAO(_Symbol, tf, i);
      if(min_ao > ao)
         min_ao = ao;
   }
   
   return min_ao;
}


 
