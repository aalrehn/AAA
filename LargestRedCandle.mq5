//+------------------------------------------------------------------+
//|                                                LargestRedCandle.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd.   |
//|                                             https://www.mql5.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

// Input parameters
input int InpMAPeriod = 20;  
input int InpMaxLookbackCandles = 50;           
input int InpPreviousCandlesToCompare = 11;       

datetime    lastAlertTime = 0;
int         handle_iMA;
double      ExtMaBuffer[];

int OnInit()
{
   handle_iMA = iMA(_Symbol, PERIOD_CURRENT, InpMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(handle_iMA == INVALID_HANDLE)
   {
      Print("Error creating MA indicator");
      return(INIT_FAILED);
   }
   
   ArraySetAsSeries(ExtMaBuffer, true);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete(0, "LargestRedCandleVerticalLine");
   ObjectDelete(0, "LargestRedCandleHorizontalLine");
   if(handle_iMA != INVALID_HANDLE)
      IndicatorRelease(handle_iMA);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{

   if(rates_total < InpMaxLookbackCandles + InpPreviousCandlesToCompare + 1) return(0);
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, rates_total, rates) <= 0)
   {
      Print("Error copying rates data, code ", GetLastError());
      return(0);
   }
   

   if(CopyBuffer(handle_iMA, 0, 0, rates_total, ExtMaBuffer) <= 0)
   {
      Print("Error copying MA data, code ", GetLastError());
      return(0);
   }
   

   int maxIndex = MathMin(InpMaxLookbackCandles + InpPreviousCandlesToCompare, rates_total);
   findLargestRedCandle(rates, ExtMaBuffer, maxIndex, InpPreviousCandlesToCompare);
   
   return(rates_total);
}

void findLargestRedCandle(const MqlRates &rates[],
                          const double &ma[],
                          int maxCandlesToCheck,
                          int previousCandlesToCompare)
{

   for(int i = previousCandlesToCompare; i < maxCandlesToCheck; i++)
   {
 
      if(rates[i].close < rates[i].open)
      {
         double currentCandleHigh = rates[i].high;
         double currentCandleLow  = rates[i].low;
         double candleLength      = currentCandleHigh - currentCandleLow;
         bool isLargerThanPrevious = true;
         
  
         for(int j = 1; j <= previousCandlesToCompare; j++)
         {
            int compareIndex = i - j;
            if(compareIndex >= 0)
            {
               double prevCandleHigh = rates[compareIndex].high;
               double prevCandleLow  = rates[compareIndex].low;
               double prevCandleLength = prevCandleHigh - prevCandleLow;
               
               if(candleLength <= prevCandleLength)
               {
                  isLargerThanPrevious = false;
                  break;
               }
            }
         }

         if(isLargerThanPrevious && ((rates[i].close - currentCandleLow) <= (candleLength * 0.05))
            && (rates[i].close < ma[i]))
         {
            // Only update if we haven't already alerted for this candle
            if(rates[i].time != lastAlertTime)
            {
               lastAlertTime = rates[i].time;
               
               // Delete existing objects before creating new ones
               ObjectDelete(0, "LargestRedCandleVerticalLine");
               ObjectDelete(0, "LargestRedCandleHorizontalLine");
               
               datetime candleTime = rates[i].time;
               
               if(!ObjectCreate(0, "LargestRedCandleVerticalLine", OBJ_VLINE, 0, candleTime, 0))
               {
                  Print("Error creating vertical line: ", GetLastError());
               }
               else
               {
                  Alert("TICKER ", _Symbol, "  TimeFrame ", EnumToString(PERIOD_CURRENT));
                  SendNotification("TICKER " + _Symbol + " TimeFrame " + EnumToString(PERIOD_CURRENT));
                  ObjectSetInteger(0, "LargestRedCandleVerticalLine", OBJPROP_COLOR, clrRed);
                  ObjectSetInteger(0, "LargestRedCandleVerticalLine", OBJPROP_WIDTH, 2);
                  ObjectSetInteger(0, "LargestRedCandleVerticalLine", OBJPROP_STYLE, STYLE_DASH);
               }
               
               if(!ObjectCreate(0, "LargestRedCandleHorizontalLine", OBJ_HLINE, 0, 0, currentCandleLow))
               {
                  Print("Error creating horizontal line: ", GetLastError());
               }
               else
               {
                  ObjectSetInteger(0, "LargestRedCandleHorizontalLine", OBJPROP_COLOR, clrRed);
                  ObjectSetInteger(0, "LargestRedCandleHorizontalLine", OBJPROP_WIDTH, 2);
                  ObjectSetInteger(0, "LargestRedCandleHorizontalLine", OBJPROP_STYLE, STYLE_DASH);
               }
            }
            return;
         }
      }
   }
   Print("No qualifying red candle found below Moving Average within the most recent ", maxCandlesToCheck, " candles.");
}
