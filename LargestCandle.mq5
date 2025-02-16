//+------------------------------------------------------------------+
//|                                                LargestCandle.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1


input int InpMAPeriod = 20;  


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
   ObjectDelete(0, "LargestCandleVerticalLine");
   ObjectDelete(0, "LargestCandleHorizontalLine");
   if(handle_iMA != INVALID_HANDLE)
      IndicatorRelease(handle_iMA);
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if(rates_total < 12) return(0);
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   

   if(CopyRates(_Symbol, PERIOD_CURRENT, 0, rates_total, rates) <= 0)
   {
      Print("Error copying rates data, code ", GetLastError());
      return(0);
   }
   
   // Get MA values
   if(CopyBuffer(handle_iMA, 0, 0, rates_total, ExtMaBuffer) <= 0)
   {
      Print("Error copying MA data, code ", GetLastError());
      return(0);
   }
   
   findLargestGreenCandle(rates, ExtMaBuffer, rates_total, 11);
   
   return(rates_total);
}


void findLargestGreenCandle(const MqlRates &rates[],
                           const double &ma[],
                           int rates_total,
                           int previousCandlesToCompare)
{
   // Start from the most recent candle (index 0) and work backwards
   for(int i = 0; i < rates_total - previousCandlesToCompare; i++)
   {
      if(rates[i].close > rates[i].open) // Detect green candle
      {
         double currentCandleHigh = rates[i].high;
         double currentCandleLow = rates[i].low;
         double candleLength = currentCandleHigh - currentCandleLow;
         bool isLargerThanPrevious = true;
         
         // Check next X candles forward in time (higher indices)
         for(int j = 1; j <= previousCandlesToCompare; j++)
         {
            int compareIndex = i + j;
            if(compareIndex < rates_total)
            {
               double nextCandleHigh = rates[compareIndex].high;
               double nextCandleLow = rates[compareIndex].low;
               double nextCandleLength = nextCandleHigh - nextCandleLow;
               
               if(candleLength <= nextCandleLength)
               {
                  isLargerThanPrevious = false;
                  break;
               }
            }
         }
         
         if(isLargerThanPrevious && ((currentCandleHigh - rates[i].close) <= (candleLength * 0.05))) // Ensure high is near close
         {
            if(rates[i].close > ma[i]) // Check if candle is above Moving Average
            {
               if(rates[i].time != lastAlertTime)
               {
                  lastAlertTime = rates[i].time;
                  
                  ObjectDelete(0, "LargestCandleVerticalLine");
                  ObjectDelete(0, "LargestCandleHorizontalLine");
                  
                  datetime candleTime = rates[i].time;
                  
                  if(!ObjectCreate(0, "LargestCandleVerticalLine", OBJ_VLINE, 0, candleTime, 0))
                  {
                     Print("Error creating vertical line: ", GetLastError());
                  }
                  else
                  {
                     Alert("TICKER ", _Symbol, "  TimeFrame ", EnumToString(PERIOD_CURRENT));
                     SendNotification("TICKER " + _Symbol + " TimeFrame " + EnumToString(PERIOD_CURRENT));
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_COLOR, clrGreen);
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_WIDTH, 2);
                     ObjectSetInteger(0, "LargestCandleVerticalLine", OBJPROP_STYLE, STYLE_DASH);
                  }
                  
                  if(!ObjectCreate(0, "LargestCandleHorizontalLine", OBJ_HLINE, 0, 0, currentCandleHigh))
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
   }
   Print("No qualifying green candle found above Moving Average.");
}
