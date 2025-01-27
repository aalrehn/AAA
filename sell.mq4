//+------------------------------------------------------------------+
//|                                                LargestCandle.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

datetime lastAlertTime = 0;
double ExtLineBuffer[];
int InpMAPeriod = 11; // Example EMA period

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, ExtLineBuffer, INDICATOR_DATA); // Link buffer for visualization
   ArraySetAsSeries(ExtLineBuffer, true); // Ensure array is indexed as a series
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
  
   CalculateSimpleMA(rates_total, prev_calculated, close);

  
   findLargestRedCandle(time, open, high, low, close, rates_total, 11);

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Simple Moving Average                                       |
//+------------------------------------------------------------------+
void CalculateSimpleMA(int rates_total,int prev_calculated,const double &price[])
  {
   int i,limit;
//--- first calculation or number of bars was changed
   if(prev_calculated==0)
   
     {
      limit=InpMAPeriod;
      //--- calculate first visible value
      double firstValue=0;
      for(i=0; i<limit; i++)
         firstValue+=price[i];
      firstValue/=InpMAPeriod;
      ExtLineBuffer[limit-1]=firstValue;
     }
   else
      limit=prev_calculated-1;
//--- main loop
   for(i=limit; i<rates_total && !IsStopped(); i++)
      ExtLineBuffer[i]=ExtLineBuffer[i-1]+(price[i]-price[i-InpMAPeriod])/InpMAPeriod;
//---
  }

//+------------------------------------------------------------------+
//| Find the largest red candle when price is above EMA              |
//+------------------------------------------------------------------+
void findLargestRedCandle(const datetime &time[], const double &open[], const double &high[],
                          const double &low[], const double &close[], int rates_total, int previousCandlesToCompare)
{
   for (int i = 0; i <= rates_total - previousCandlesToCompare; i++)
   {
      
      if (close[i] < ExtLineBuffer[i]) 
      {
         if (close[i] < open[i]) 
         {
            double currentCandleHigh = high[i];
            double currentCandleLow = low[i];
            double candleLength = currentCandleHigh - currentCandleLow;
            bool isLargerThanPrevious = true;

            for (int j = 1; j <= previousCandlesToCompare; j++)
            {
               int compareIndex = i + j;
               if (compareIndex < rates_total)
               {
                  double nextCandleHigh = high[compareIndex];
                  double nextCandleLow = low[compareIndex];
                  double nextCandleLength = nextCandleHigh - nextCandleLow;

                  if (candleLength <= nextCandleLength)
                  {
                     isLargerThanPrevious = false;
                     break;
                  }
               }
            }

            if (isLargerThanPrevious && ((currentCandleLow - close[i]) <= (candleLength * 0.15))) // Low close to candle's low
            {
               if (time[i] != lastAlertTime)
               {
                  lastAlertTime = time[i];

                  // Delete previous objects
                  ObjectDelete(0, "LargestCandleVerticalLine");
                  ObjectDelete(0, "LargestCandleHorizontalLine");

                  // Create vertical line
                  datetime candleTime = time[i];
                  if (!ObjectCreate(0, "LargestCandleVerticalLine", OBJ_VLINE, 0, candleTime, 0))
                     Print("Error creating vertical line: ", GetLastError());
                  else
                  {
                     Alert("TICKER SELL ", _Symbol, "  TimeFrame ", Period());
                     SendNotification("TICKER " + _Symbol + " TimeFrame " + IntegerToString(Period()));
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_COLOR, clrRed);
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_WIDTH, 2);
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_STYLE, STYLE_DASH);
                  }

                  // Create horizontal line
                  if (!ObjectCreate(0, "LargestCandleHorizontalLine", OBJ_HLINE, 0, 0, currentCandleLow))
                     Print("Error creating horizontal line: ", GetLastError());
                  else
                  {
                     ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_COLOR, clrRed);
                     ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_WIDTH, 2);
                     ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_STYLE, STYLE_DASH);
                  }
               }

               return;
            }
         }
      }
   }
   Print("No qualifying red candle found above EMA.");
}
