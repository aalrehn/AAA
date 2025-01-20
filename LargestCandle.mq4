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

int OnInit()
{
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
   findLargestGreenCandle(time, open, high, low, close, rates_total, 11);
   return(rates_total);
}

void findLargestGreenCandle(const datetime &time[], const double &open[], const double &high[], const double &low[], const double &close[], int rates_total, int previousCandlesToCompare)
{
   for (int i = 0; i <= rates_total - previousCandlesToCompare; i++)
   {
      if (close[i] > open[i])
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

         if (isLargerThanPrevious && ((currentCandleHigh - close[i]) <= (candleLength * 0.05)))
         {
            if (time[i] != lastAlertTime)
            {
               lastAlertTime = time[i];

               ObjectDelete(0, "LargestCandleVerticalLine");
               ObjectDelete(0, "LargestCandleHorizontalLine");

               datetime candleTime = time[i];

               if (!ObjectCreate(0, "LargestCandleVerticalLine", OBJ_VLINE, 0, candleTime, 0))
               {
                  Print("Error creating vertical line: ", GetLastError());
               }
               else
               {
                  Alert("TICKER ", _Symbol, "  TimeFrame ", Period());
                  SendNotification("TICKER " + _Symbol + " TimeFrame " + IntegerToString(Period()));
                  ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_COLOR, clrGreen);
                  ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_WIDTH, 2);
                  ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_STYLE, STYLE_DASH);
               }

               if (!ObjectCreate(0, "LargestCandleHorizontalLine", OBJ_HLINE, 0, 0, currentCandleHigh))
               {
                  Print("Error creating horizontal line: ", GetLastError());
               }
               else
               {
                  ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_COLOR, clrGreen);
                  ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_WIDTH, 2);
                  ObjectSetInteger(0, "LargestCandleHorizontalLine", OBJPROP_STYLE, STYLE_DASH);
               }
            }

            return;
         }
      }
   }
   Print("No qualifying green candle found.");
}
