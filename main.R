#Asher Stout 300432820
#INFO281 Project

library(tidyverse)




# --------LOAD AND FORMAT DATA RELATED TO TRADE BALANCE--------
# Formats the passed economic data into an acceptable format for the purposes of this project
# @param toFormat the data to format
# @return the formatted data, with irrelevant columns discarded
format.project.econdata <- function(toFormat) {
  if (!is.data.frame(toFormat)) {
    stop("Unexpected Argument Format.", call. = T)
  }
  formatted = subset(
    toFormat,
    select = c(
      "Reporter_code",
      "Reporter_desc",
      "Flow_desc",
      "Indicator_desc",
      "Unit_desc",
      "Year",
      "Value"
    )
  )
}

#Declare constants for economic file loading
address <-
  "./data/"
econfiles <-
  c(
    "Developing_Nations IM-EX[GOOD] (2008-2017).csv",
    "Developing_Nations IM-EX[GOOD-TYPE] (2008-2017).csv",
    "Developing_Nations IM-EX[SERVICE] (2008-2017).csv"
  )

#Load in and format raw economic data recursively
econ_iterator <- 1L
while (econ_iterator <= length(econfiles))
{
  econfile <-
    read_csv(paste(address, econfiles[econ_iterator], sep = ""))
  econfile <- format.project.econdata(econfile)
  if (econ_iterator == 1L) {
    econdata <- econfile
  }
  else{
    econdata <- full_join(econdata, econfile)
  }
  econ_iterator = econ_iterator + 1
}
econdata <- spread(econdata, Indicator_desc, Value)
econdata <-
  econdata[!(econdata$Reporter_desc == "Kiribati"), ] #remove Kiribati due to lack of relevant inequality data
econdata[econdata == 0] <- NA #converts all '0' values into NAs

#Rename columns to better reflect data
colnames(econdata) <-
  c(
    "Country_code",
    "Country",
    "Trade_flow",
    "Units",
    "Year",
    "Agricultural_products",
    "Commercial_services",
    "Fuels_and_Mining_products",
    "Good_related_services",
    "Manufactured_products",
    "Other_commercial_services",
    "Total_products",
    "Transport_services",
    "Travel_service"
  )

#Format economic data to accomodate import-export columns
econdata <-
  pivot_wider(econdata,
              names_from = Trade_flow,
              values_from = colnames(econdata[6:14]))

#Calculate net trade values for each category
econdata <-
  mutate(
    econdata,
    Agricultural_products_net = Agricultural_products_Exports - Agricultural_products_Imports,
    Fuels_and_Mining_products_net = Fuels_and_Mining_products_Exports - Fuels_and_Mining_products_Imports,
    Good_related_services_net = Good_related_services_Exports - Good_related_services_Imports,
    Manufactured_products_net = Manufactured_products_Exports - Manufactured_products_Imports,
    Other_commercial_services_net = Other_commercial_services_Exports - Other_commercial_services_Imports,
    Transport_services_net = Transport_services_Exports - Transport_services_Imports,
    Travel_service_net = Travel_service_Exports - Travel_service_Imports,
    Commercial_services_net = Commercial_services_Exports - Commercial_services_Imports,
    Total_products_net = Total_products_Exports - Total_products_Imports,
    Trade_Balance = Total_products_net + Commercial_services_net
  )

#Rename countries to match other datasets & maintain consistency
econdata$Country[econdata$Country == "Democratic Republic of the Congo"] <- "Congo, Dem. Rep."
econdata$Country[econdata$Country == "The Gambia"] <- "Gambia, The"
econdata$Country[econdata$Country == "Lao People's Democratic Republic"] <- "Lao PDR"
econdata$Country[econdata$Country == "Yemen"] <- "Yemen, Rep."

#Divide all values to represent USD (millions) 
econdata[colnames(econdata)[-(1:4)]] <- econdata[colnames(econdata)[-(1:4)]]/1000000


#Write econdata to a new file
write_csv(
  econdata,
  paste(
    address,
    "Developing_Nations IM-EX[FORMATTED] (2008-2017).csv",
    sep = ""
  )
)


# --------LOAD, FORMAT, AND EXPORT DATA RELATED TO INEQUALITY--------
#Load in inqeuality data
inqdata <-
  read_csv(
    paste(
      address,
      "Developing_Nations Inequality[POVERTY] (2008-2017).csv",
      sep = ""
    ),
    col_types = "ccccdddddddddd"
  )

#Format data, removing irrelevant columns and null rows
inqdata <-
  gather(
    inqdata,
    "2008 [YR2008]",
    "2009 [YR2009]",
    "2010 [YR2010]",
    "2011 [YR2011]",
    "2012 [YR2012]",
    "2013 [YR2013]",
    "2014 [YR2014]",
    "2015 [YR2015]",
    "2016 [YR2016]",
    "2017 [YR2017]",
    key = "Year",
    value = "Index"
  )
inqdata <-
  separate(inqdata,
           Year,
           sep = " ",
           into = c("Year", "year-code"))
inqdata <-
  subset(inqdata,
         select = c("Series Name", "Country Name", "Country Code", "Year", "Index"))
inqdata <-
  inqdata[(
    inqdata$`Series Name` == "Poverty headcount ratio at national poverty lines (% of population)" |
      inqdata$`Series Name` == "GINI index (World Bank estimate)" |
      inqdata$`Series Name` == "Income share held by highest 10%"
  ), ]
inqdata <- na.omit(inqdata)
inqdata <- spread(inqdata, 'Series Name', Index)
inqdata <-
  inqdata[!(inqdata$`Country Name` == "Kiribati"), ] #remove Kiribati due to lack of relevant inequality data

#Rename columns to better reflect data and ensure columns are of correct type
colnames(inqdata) <-
  c(
    "Country",
    "Country_code",
    "Year",
    "GINI_index",
    "Income_share_held_by_top_10%",
    "Poverty_headcount_ratio_%_(at_national_lines)"
  )
inqdata$Year <- as.numeric(as.character(inqdata$Year))

#Write inequality data to a formatted file
write_csv(
  inqdata,
  paste(
    address,
    "Developing_Nations Inequality[FORMATTED] (2008-2017).csv",
    sep = ""
  )
)


# --------LOAD, FORMAT, AND EXPORT DATA RELATED TO NZ--------
#Read in NZ data from a csv
nzdata <- read_csv(paste(address,
                         "NZ_Trade_Data IM-EX (2017).csv",
                         sep = ""))

#Format the data appropriately
nzdata <-
  subset(
    nzdata,
    select = c(
      "Partner Name",
      "Trade Balance (US$ Thousand)",
      "Export (US$ Thousand)",
      "Import (US$ Thousand)"
    )
  )
colnames(nzdata) <-
  c("Country",
    "Trade_balance_(thousand_USD)",
    "Exports_(thousand_USD)",
    "Imports_(thousand_USD)")

#remove all countries this analysis isn't concerned with, and rename them appropriately (if there are any issues)
nzdata <-
  nzdata[(
    nzdata$Country %in% append(unique(inqdata$Country), c("East Timor", "Yemen"))
  ), ]
nzdata[nzdata$Country == "East Timor", 1] <- "Timor-Leste"

#Unfortunately trade data between New Zealand and Angola, Comoros, and Guinea-Bissau is unavailable; 
#these countries are not present in this section of the analysis.

#add 3-letter country codes (used later for the leaflet map) and remove countries with no NZ trade data and map projection
nzdata <- nzdata[order(nzdata$Country),]
codes <- unique(inqdata$Country_code)
codes <- codes[!( codes %in% c("AGO", "COM", "GNB"))]
nzdata <- cbind(nzdata, codes)
nzdata <- nzdata[order(nzdata$codes), ]
nzdata <- nzdata[!(nzdata$codes %in% c("STP", "TUV")), ]

#Lastly write this data to a formatted file
write_csv(
  nzdata,
  paste(
    address,
    "NZ_Trade_Data IM-EX[FORMATTED] (2017).csv",
    sep = ""
  )
)

#--------PERFORM ANALYSIS ON DATA--------
aggrdata <- merge(econdata, inqdata[, -2], by = c("Country", "Year"))

#Use Kendall Correlation: Kendall rank correlation (non-parametric) is an alternative to Pearson’s correlation (parametric) 
#when the data you’re working with has failed one or more assumptions of the test. This is also the best alternative to Spearman 
#correlation (non-parametric) when your sample size is small and has many tied ranks.

#Find p-values AND r-values of each possible pairing of inequality/economic indicators
p_corrdata <- data.frame(Economic_indicator = character(length = 10),
                         GINI_index = integer(length = 10))
p_corrdata$Economic_indicator <- colnames(aggrdata[23:32])

p_corrdata$GINI_index <- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["GINI_index"], method = "spearman")$p, digits = 3)})
p_corrdata$"Income_share_held_by_top_10%"<- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["Income_share_held_by_top_10%"], method = "spearman")$p, digits = 3)})
p_corrdata$"Poverty_headcount_ratio_%_(at_national_lines)" <- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["Poverty_headcount_ratio_%_(at_national_lines)"], method = "spearman")$p, digits = 3)})


r_corrdata <- data.frame(Economic_indicator = character(length = 10),
                         GINI_index = integer(length = 10))
r_corrdata$Economic_indicator <- colnames(aggrdata[23:32])
r_corrdata$GINI_index <- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["GINI_index"], method = "spearman")$r, digits = 3)})
r_corrdata$"Income_share_held_by_top_10%"<- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["Income_share_held_by_top_10%"], method = "spearman")$r, digits = 3)})
r_corrdata$"Poverty_headcount_ratio_%_(at_national_lines)" <- by(p_corrdata, 1:nrow(p_corrdata), function(row){ row$GINI_index <- 
  round(psych::corr.test(aggrdata[row$Economic_indicator],  aggrdata["Poverty_headcount_ratio_%_(at_national_lines)"], method = "spearman")$r, digits = 3)})
