#### Load libraries ####

library(MASS)
library(tidyverse)
library(here)
library(lme4)
library(RLRsim)
library(ggdist)
library(tidyquant)
library(dplyr)

# set directories
clean_data_dir <- here("data", "clean")

# get excel file name
totals <- "totals_all.csv"

# load dataframe
mussel_df <- read_csv(here(clean_data_dir, totals), show_col_types = FALSE)

#abs of dry value for now
mussel_df$dry_value <- abs(mussel_df$dry_value)

#years as year from 2010
#mussel_df$year <- mussel_df$year - 2010

#as category
mussel_df$year <- as.factor(mussel_df$year)
mussel_df$wria_nr <- as.factor(mussel_df$wria_nr)
mussel_df$lio_areas <- as.factor(mussel_df$lio_areas)

#remove Penn Cove reference samples
mussel_df <- mussel_df[!is.na(mussel_df$fund_source),]
mussel_df <- subset(mussel_df, site_name!="Penn Cove Reference")

#remove samples from outside Puget sound
mussel_df <- subset(mussel_df, longitude > -123.5)


#create simple regions based on longitude
# mussel_df <- mussel_df %>% mutate(region = case_when(longitude > -122.75 & latitude > 47.6 ~  'Northeast',
#                                                      longitude > -122.75 & latitude < 47.6 ~  'Southeast',
#                                                      longitude < -122.75 ~ 'West'
# ))
# mussel_df$region <- as.factor(mussel_df$region)



#create analyte dataframes
PA_df <- mussel_df %>%
  filter(mussel_df$analyte == "SumPAHs16")
PA_df <- PA_df[complete.cases(PA_df),]

#### subregion things ####
table(PA_df$year)
table(PA_df$year, PA_df$lio_areas)
table(PA_df$year, PA_df$wria_nr)


#### means by subregions ####
all_mean <- ddply(PA_df, c("year"), summarise,
                    mean = mean(dry_value))
#change is + - -
lio_mean <-ddply(PA_df, c("lio_areas","year"), summarise,
                 mean = mean(dry_value))
wria_mean <- ddply(PA_df, c("wria_nr","year"), summarise,
      mean = mean(dry_value))

#### raincloud plots ####
##over years
pdf("PAHs_Over_Years.pdf")
PA_df %>% 
  ggplot(aes(x = year, y = log10(dry_value))) +
  ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
  geom_boxplot(width = .1, outlier.shape = NA) +
  ggdist::stat_dots(side = "left", dotsize = .1, justification = 1.1, binwidth = .1)+
  theme(axis.text.x=element_text(angle=270,hjust=1)) +
  xlab("Year") +
  ylab("log10(dry value)")+
  ggtitle("PAHs Across Years")
dev.off()
## over LIOs
pdf("PAHs_Over_LIOs.pdf")
PA_df %>% 
  ggplot(aes(x = lio_areas, y = log10(dry_value))) +
  ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
  geom_boxplot(width = .1, outlier.shape = NA) +
  ggdist::stat_dots(side = "left", dotsize = .1, justification = 1.1, binwidth = .1)+  theme(axis.text.x=element_text(angle=315,hjust = 0.01)) +
  xlab("LIO Area") +
  ylab("log10(dry value)")+
  ggtitle("PAHs Across LIOs")
dev.off()
##over wria_nr
pdf("PAHs_Over_WRIAs.pdf")
PA_df %>% 
  ggplot(aes(x = wria_nr, y = log10(dry_value))) +
  ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
  geom_boxplot(width = .1, outlier.shape = NA) +
  ggdist::stat_dots(side = "left", dotsize = .1, justification = 1.1, binwidth = .1)+
 theme(axis.text.x=element_text(angle=270,hjust=1)) +
 xlab("WRIA") +
 ylab("log10(dry value)")+
  ggtitle("PAHs Across WRIAs")
dev.off()
#### WRIA plot loop ####
plot_list = list()
for (i in unique(PA_df$wria_nr)){
  wria_subset <- PA_df[PA_df$wria_nr==i,]
  p = wria_subset %>%
    ggplot(aes(x = year, y = log10(dry_value))) +
    ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
    geom_boxplot(width = .1, outlier.shape = NA) +
    ggdist::stat_dots(side = "left", dotsize = .05, justification = 1.1, binwidth = .1) +
   ggtitle(paste("PAHs - WRIA #",i)) +
   # theme(axis.text.x=element_text(angle=270,hjust=1)) +
    xlab("Year") +
    ylab("log10(dry value)")
  plot_list[[i]] = p
                                }
#end plot loop
#start plot to pdf loop

pdf("PAH_WRIA_plots.pdf")
for (i in unique(PA_df$wria_nr)){
  print(plot_list[[i]])
}
dev.off()

#### LIO plot loop ####
plot_list = list()
for (i in unique(PA_df$lio_areas)){
  wria_subset <- PA_df[PA_df$lio_areas==i,]
  p = wria_subset %>%
    ggplot(aes(x = year, y = log10(dry_value))) +
    ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
    geom_boxplot(width = .1, outlier.shape = NA) +
    ggdist::stat_dots(side = "left", dotsize = .1, justification = 1.1, binwidth = .1) +
    theme(axis.text.x=element_text(angle=270,hjust=1)) +
    xlab("LIO") +
    ylab("log10(dry value)")+
    ggtitle(paste("PAHs - LIO -",i))
  plot_list[[i]] = p
}
#end plot loop
#start plot to pdf loop

pdf("PAH_LIO_plots.pdf")
for (i in unique(PA_df$lio_areas)){
  print(plot_list[[i]])
}
dev.off()

#### 2020 only plots ####
PA20_df <- PA_df %>% filter(PA_df$year == 2020)
pdf("2020_PAHs_Over_WRIAs.pdf")
PA20_df %>% 
  ggplot(aes(x = wria_nr, y = log10(dry_value))) +
  ggdist::stat_halfeye(adjust = .5, width = .3, .width = 0, justification = -.3, point_colour = NA) + 
  geom_boxplot(width = .1, outlier.shape = NA) +
  ggdist::stat_dots(side = "left", dotsize = .1, justification = 1.1, binwidth = .1)+
  theme(axis.text.x=element_text(angle=270,hjust=1)) +
  xlab("WRIA") +
  ylab("log10(dry value)")+
  ggtitle("2020 - PAHs Across WRIAs")
dev.off()

#### anova ####
PA_aov <- aov(PA_df$dry_value ~ PA_df$wria_nr, data = PA_df)



