Time::DATE_FORMATS[:govuk_date] = '%-d %B %Y'
Time::DATE_FORMATS[:govuk_date_short_month] = '%-d %b %Y'
Date::DATE_FORMATS[:govuk_date] = '%-d %B %Y'

Time::DATE_FORMATS[:month_and_year] = '%B %Y'
Date::DATE_FORMATS[:month_and_year] = '%B %Y'

Time::DATE_FORMATS[:short_month_and_year] = '%b %Y'
Date::DATE_FORMATS[:short_month_and_year] = '%b %Y'

Time::DATE_FORMATS[:govuk_date_and_time] = lambda do |time|
  format = if time >= time.midday && time <= time.midday.end_of_minute
             '%e %B %Y at %l%P (midday)'
           elsif time >= time.midnight && time <= time.midnight.end_of_minute
             '%e %B %Y at %l%P (midnight)'
           else
             '%e %B %Y at %l:%M%P'
           end

  time.strftime(format).squish
end

Time::DATE_FORMATS[:govuk_time] = lambda do |time|
  format = if time >= time.midday && time <= time.midday.end_of_minute
             '%l%P (midday)'
           elsif time >= time.midnight && time <= time.midnight.end_of_minute
             '%l%P (midnight)'
           else
             '%l:%M%P'
           end

  time.strftime(format).squish
end
