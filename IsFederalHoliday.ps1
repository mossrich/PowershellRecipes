<#
Implements Federal Holiday algorithm from https://www.law.cornell.edu/uscode/text/5/6103

* New Year’s Day, January 1.
* Birthday of Martin Luther King, Jr., the third Monday in January.
* Washington’s Birthday, the third Monday in February.
* Memorial Day, the last Monday in May.
* Juneteenth National Independence Day, June 19. (Newly added as of 2021)
* Independence Day, July 4.
* Labor Day, the first Monday in September.
* Columbus Day, the second Monday in October.
* Veterans Day, November 11.
* Thanksgiving Day, the fourth Thursday in November.
* Christmas Day, December 25.

For regular Monday through Friday workers, holidays that land on a Saturday will be observed on the Friday before. I've read in other places that holidays landing on a Sunday will be observed the following Monday.
#>

function IsFederalHoliday([datetime] $DateToCheck = (Get-Date)){
  [int]$year = $DateToCheck | %{$_.Year + $(If($_.Day -eq 31 -and $_.Month -eq 12 -and $_.DayOfWeek -eq 'Friday'){1})}
  $HolidaysInYear = (@(
    [datetime]"1/1/$year", # 1/1/2021 on Saturday is observed on 12/31/2021 (prior year)
    (24..30 | %{([datetime]"5/1/$year").AddDays($_)}|?{$_.DayOfWeek -eq 'Monday'})[-1], #Memorial Day
    $(If($year -ge 2021){[datetime]"6/19/$year"}Else{[datetime]"1/1/$year"}), #Juneteenth is a federal holiday since 2021
    [datetime]"7/4/$year",#Independence Day
    (0..6 | %{([datetime]"9/1/$year").AddDays($_)}|?{$_.DayOfWeek -eq 'Monday'})[0], #Labor Day - first Mon in Sept.
    [datetime]"11/11/$year",#Veterans Day
    (0..29 | %{([datetime]"11/1/$year").AddDays($_)}|?{$_.DayOfWeek -eq 'Thursday'})[3],#Thanksgiving - 4th Thu in Nov.
    [datetime]"12/25/$year"#Christmas
  ) | %{$_.AddDays($(If($_.DayOfWeek -eq 'Saturday'){-1}) + $(If($_.DayOfWeek -eq 'Sunday'){+1})) })
  Return $HolidaysInYear.Contains($DateToCheck.Date)
}

0..364|%{([datetime]'1/1/2021').AddDays($_)} | ?{IsFederalHoliday $_} #List of holidays for 2021 - a weird year because 2022 New Years Day is observed in 2021
