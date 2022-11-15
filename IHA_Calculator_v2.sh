#!/bin/sh
echo "This script was developed by the Deparment of Physical Geography of Utrecht University, the Netherlands"


dis1="$1"    # Discharge pre-alterations input
dis2="$2"    # Discharge post-alterations input

# Start up
echo ""
echo "Starting the calculator for Indicators of Hydrologic Alterations (Martinez Santa-Maria et al., 2008)."
echo "Using $1 as pre-alterations database, and $2 as post-alterations database."
echo "For a description of each of the indicators see: Quantifying sustainable water resources in the Danube catchment by implementing environmental flow requirements in the PCR-GLOBWB model by Hosper & van Beek, 2022."
echo ""
# load CDO module
module load CDO

# Enable or disable equal distribution of parameters
# To-Do: Add this functionality to the corresponding IAHs (IAH1b, IAH3, IAH12, IAH18, IAH19)
echo "There are a total of 15 parameters in this version of the IHA Calculator."
echo "Three of these have monthly values that could be given their own weight in the final calculation." 
echo "This would mean that in total there would be 59 parameters (4 par x 12 months + 11 par)."
echo "The monthly parameters would then contribute to 80%+ of the final average."
read -p "Should monthly parameters be 12 different IAH values (y/n): " multipar

# Ask for information 
read -p "Environmental starting year: " ESY
read -p "Environmental end year: " EEY
read -p "Altered starting year: " ASY
read -p "Altered end year: " AEY

envs=$ESY
alts=$ASY
enve=$EEY
alte=$AEY


# Create map of ones, needed for IAH ratio calculation
echo ""
echo "Creating maps required for the calculations of the Indicators."
cdo -L -timavg -ifthenc,1 -eq $dis1 $dis1 tmp_1.nc

# Calculate min & max for yearly and daily
cdo -L -selyear,$envs/$enve -yearmax $dis1 tmp_max1.nc
cdo -L -selyear,$envs/$enve -yearmin $dis1 tmp_min1.nc
cdo -L -selyear,$alts/$alte -yearmax $dis2 tmp_max2.nc
cdo -L -selyear,$alts/$alte -yearmin $dis2 tmp_min2.nc

# Habitual Data
echo ""
echo "Starting Calculation: The Habitual Data Indicators"

echo ""
echo "Calculation: IAH1"
# IAH 1: Mean Annual Volume
cdo -L -selyear,$envs/$enve -yearavg $dis1 tmp_ya1.nc
cdo -L -selyear,$alts/$alte -yearavg $dis2 tmp_ya2.nc

# IAH 1 Ratio
cdo -L -div -timavg tmp_ya2.nc -timavg tmp_ya1.nc tmp_IAH1.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH1.nc -div tmp_1.nc tmp_IAH1.nc tmp_IAH1.nc IAH1.nc
echo "Completed: IAH1"

echo ""
echo "Calculation: IAH1b"
# IAH 1b: Monthly Mean Volume
cdo -L -ymonavg -selyear,$envs/$enve $dis1 tmp_ma1.nc
cdo -L -ymonavg -selyear,$alts/$alte $dis2 tmp_ma2.nc

# IAH 1b Ratio
if [ $multipar == "y" ]
then
cdo -L -div tmp_ma2.nc tmp_ma1.nc tmp_IAH1b.nc
elif [ $multipar == "n" ]
then
cdo -L -timavg -div tmp_ma2.nc tmp_ma1.nc tmp_IAH1b.nc
else
echo "Wrong input, next time choose y or n. Average taken as default." 
cdo -L -timavg -div tmp_ma2.nc tmp_ma1.nc tmp_IAH1b.nc
fi
cdo -L -ifthenelse -gtc,1 tmp_IAH1b.nc -div tmp_1.nc tmp_IAH1b.nc tmp_IAH1b.nc IAH1b.nc
echo "Completed: IAH1b"

echo ""
echo "Calculation: IAH2"
# IAH 2: Difference between Annual Max & Annual Min
cdo -L -timavg -sub tmp_max1.nc tmp_min1.nc tmp_diff1.nc # First calculate the difference between max and min, then find the average.
cdo -L -timavg -sub tmp_max2.nc tmp_min2.nc tmp_diff2.nc

# IAH 2 Ratio
cdo div tmp_diff2.nc tmp_diff1.nc tmp_IAH2.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH2.nc -div tmp_1.nc tmp_IAH2.nc tmp_IAH2.nc IAH2.nc
echo "Completed: IAH2"


# IAH 3: Month with min and max water volume
# I can find when the monthly maximums are (which month) but I can only show these dates, not calculate anything with them...
# The calculation for this parameter is 1 - 1/6*(change in months)
echo ""
echo "IAH3 is missing for now."

#~ cdo ymonmax $dis1 tmp_mmax1.nc
#~ cdo ymonmax $dis2 tmp_mmax2.nc

#~ cdo ymonmin $dis1 tmp_mmin1.nc
#~ cdo ymonmin n$dis2 tmp_mmin2.nc

# Can maybe use a python script with netCDF4 to calculate the change of months


echo ""
echo "Calculation: IAH4"
# IAH 4: Difference between daily 10% and daily 90%
cdo -L -yearpctl,10 -selyear,$envs/$enve $dis1 tmp_min1.nc tmp_max1.nc tmp_1d10.nc
cdo -L -yearpctl,90 -selyear,$envs/$enve $dis1 tmp_min1.nc tmp_max1.nc tmp_1d90.nc
cdo sub tmp_1d90.nc tmp_1d10.nc tmp_ddiff1.nc
cdo timavg tmp_ddiff1.nc tmp_ddiffavg1.nc

cdo -L -yearpctl,10 -selyear,$alts/$alte $dis2 tmp_min2.nc tmp_max2.nc tmp_2d10.nc
cdo -L -yearpctl,90 -selyear,$alts/$alte $dis2 tmp_min2.nc tmp_max2.nc tmp_2d90.nc
cdo sub tmp_2d90.nc tmp_2d10.nc tmp_ddiff2.nc
cdo timavg tmp_ddiff2.nc tmp_ddiffavg2.nc

# IAH 4 Ratio
cdo div tmp_ddiffavg2.nc tmp_ddiffavg1.nc tmp_IAH4.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH4.nc -div tmp_1.nc tmp_IAH4.nc tmp_IAH4.nc IAH4.nc
echo "Completed: IAH4"

echo ""
echo "Calculating: Extreme Data Floods"

echo ""
echo "Calculation: IAH5"
# Extreme Data
# IAH 5: Average of maximum daily flows (Qc)
# IAH 5 Ratio
cdo -L -div -timavg tmp_max2.nc -timavg tmp_max1.nc tmp_IAH5.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH5.nc -div tmp_1.nc tmp_IAH5.nc tmp_IAH5.nc IAH5.nc
echo "Completed: IAH5"

# IAH 6: Effective discharge (??) -> Still no clue after reading Perez-Sanchez et al. (2020)
echo ""
echo "IAH6 is missing for now."

# IAH 7: Connectivity discharge (Qconec) -> Still no clue after reading Perez-Sanchez et al. (2020)
echo ""
echo "IAH7 is missing for now."

echo ""
echo "Calculation: IAH8"
# IAH 8: Q5% exceedance probability
cdo -L -yearpctl,95 -selyear,$envs/$enve $dis1 tmp_min1.nc tmp_max1.nc tmp_1y95.nc
cdo timavg tmp_1y95.nc tmp_1ya95.nc
cdo -L -yearpctl,95 -selyear,$alts/$alte $dis2 tmp_min2.nc tmp_max2.nc tmp_2y95.nc
cdo timavg tmp_2y95.nc tmp_2ya95.nc

# IAH 8 Ratio
cdo div tmp_2ya95.nc tmp_1ya95.nc tmp_IAH8.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH8.nc -div tmp_1.nc tmp_IAH8.nc tmp_IAH8.nc IAH8.nc
echo "Completed: IAH8"

echo ""
echo "Calculation: IAH9"
# IAH 9: CV Qc
cdo -L -mulc,100 -div -timstd tmp_max1.nc -timmean tmp_max1.nc tmp_cvMax1.nc
cdo -L -mulc,100 -div -timstd tmp_max2.nc -timmean tmp_max2.nc tmp_cvMax2.nc

# IAH 9 Ratio
cdo div tmp_cvMax2.nc tmp_cvMax1.nc tmp_IAH9.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH9.nc -div tmp_1.nc tmp_IAH9.nc tmp_IAH9.nc IAH9.nc
echo "Completed: IAH9"

echo ""
echo "Calculation: IAH10"
# IAH 10: CV Q5%
cdo -L -mulc,100 -div -timstd tmp_1y95.nc -timmean tmp_1y95.nc tmp_1cv95.nc
cdo -L -mulc,100 -div -timstd tmp_2y95.nc -timmean tmp_2y95.nc tmp_2cv95.nc

# IAH 10 Ratio
cdo div tmp_2cv95.nc tmp_1cv95.nc tmp_IAH10.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH10.nc -div tmp_1.nc tmp_IAH10.nc tmp_IAH10.nc IAH10.nc
echo "Completed: IAH10"


# IAH 11: Flood duration = consecutive days Q > Q5%
echo ""
echo "IAH 11 is missing for now"

# IAH 12: Flood seasonality = (5 - ABS(NATURAL - ALTERED) / 5)
# With 12 different values, one for each month, and NATURAL and ALTERED being the average days per month where Q > Q95%
echo ""
echo "Calculation: IAH 12"
echo "Calculating the Environmental Regime"
tmp_envs=$envs
while [ $tmp_envs -le $enve ]
do
echo ""
echo "Calculating year: $tmp_envs"
cdo -L -gt -selyear,$tmp_envs discharge_dailyTot_Environmental -timavg -selyear,$tmp_envs tmp_1y95.nc tmp_env95$tmp_envs.nc
let "tmp_envs = $tmp_envs + 1"
done
cdo mergetime tmp_env95* tmp_env_final.nc

tmp_alts=$alts
echo "Calculating the Altered Regime"
while [ $tmp_alts -le $alte ]
do
echo ""
echo "Calculating year: $tmp_alts"
cdo -L -gt -selyear,$tmp_alts discharge_dailyTot_BAU -timavg -selyear,$tmp_alts tmp_2y95.nc tmp_alt95$tmp_alts.nc
let "tmp_alts = $tmp_alts + 1"
done
cdo mergetime tmp_alt95* tmp_alt_final.nc

# IAH 12 Ratio
cdo -L -sub tmp_1.nc -mulc,0.2 -abs -sub -ymonavg -monsum tmp_alt_final.nc -ymonavg -monsum tmp_env_final.nc tmp_IAH12.nc
if [ $multipar == "y" ]
then
cdo -L -ifthen -gtc,0 tmp_IAH12.nc tmp_IAH12.nc IAH12.nc
elif [ $multipar == "n" ]
then
cdo -L -timavg -ifthen -gtc,0 tmp_IAH12.nc tmp_IAH12.nc IAH12.nc
else
echo "Average taken as default." 
cdo -L -timavg -ifthen -gtc,0 tmp_IAH12.nc tmp_IAH12.nc IAH12.nc
fi

# Remove excess files
rm tmp_alt*
rm tmp_env*

echo ""
echo "Completed: Extreme Data Floods"

echo ""
echo "Starting Calculation: Extreme Data Drought"

echo ""
echo "Calculation: IAH13"
# Extreme Data
# IAH 13: Average of minimum daily flows (Qs)
# IAH 13 Ratio
cdo -L -div -timavg tmp_min2.nc -timavg tmp_min1.nc tmp_IAH13.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH13.nc -div tmp_1.nc tmp_IAH13.nc tmp_IAH13.nc IAH13.nc
echo "Completed: IAH13"

echo ""
echo "Calculation: IAH14"
# IAH 14: Q95% exceedance probability
cdo -L -yearpctl,5 -selyear,$envs/$enve $dis1 tmp_min1.nc tmp_max1.nc tmp_1y05.nc
cdo timavg tmp_1y05.nc tmp_1ya05.nc
cdo -L -yearpctl,5 -selyear,$alts/$alte $dis2 tmp_min2.nc tmp_max2.nc tmp_2y05.nc
cdo timavg tmp_2y05.nc tmp_2ya05.nc

# IAH 14 Ratio
cdo div tmp_2ya05.nc tmp_1ya05.nc tmp_IAH14.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH14.nc -div tmp_1.nc tmp_IAH14.nc tmp_IAH14.nc IAH14.nc
echo "Completed: IAH14"

echo ""
echo "Calculation: IAH15"
# IAH 15: CV Qs
cdo -L -mulc,100 -div -timstd tmp_min1.nc -timmean tmp_min1.nc tmp_cvMin1.nc
cdo -L -mulc,100 -div -timstd tmp_min2.nc -timmean tmp_min2.nc tmp_cvMin2.nc

# IAH 15 Ratio
cdo div tmp_cvMin2.nc tmp_cvMin1.nc tmp_IAH15.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH15.nc -div tmp_1.nc tmp_IAH15.nc tmp_IAH15.nc IAH15.nc
echo "Completed: IAH15"

echo ""
echo "Calculation: IAH16"
# IAH 16: CV Q95%
cdo -L -mulc,100 -div -timstd tmp_1y05.nc -timmean tmp_1y05.nc tmp_1cv05.nc
cdo -L -mulc,100 -div -timstd tmp_2y05.nc -timmean tmp_2y05.nc tmp_2cv05.nc

# IAH 16 Ratio
cdo div tmp_2cv05.nc tmp_1cv05.nc tmp_IAH16.nc
cdo -L -ifthenelse -gtc,1 tmp_IAH16.nc -div tmp_1.nc tmp_IAH16.nc tmp_IAH16.nc IAH16.nc
echo "Completed: IAH16"

# IAH 17: Maximum consecutive days Q < Q95% in regime on average

echo ""
echo "Calculation: IAH 18"
# IAH 18: Days per month no flow - Q = 0 
# IAH 18: Days per month no flow - Q = 0 
cdo -L -selyear,$envs/$enve -eqc,0 discharge_dailyTot_Environmental tmp_1days0.nc
cdo -L -ymonavg -monsum tmp_1days0.nc tmp_1avgdays0.nc
cdo -L -selyear,$alts/$alte -eqc,0 discharge_dailyTot_BAU tmp_2days0.nc
cdo -L -ymonavg -monsum tmp_2days0.nc tmp_2avgdays0.nc

# IAH 18 Ratio
cdo -L -sub tmp_1.nc -mulc,0.2 -abs -sub -ymonsum tmp_2avgdays0.nc -ymonsum tmp_1avgdays0.nc tmp_IAH18.nc
if [ $multipar == "y" ]
then
cdo -L -ifthen -gtc,0 tmp_IAH18.nc tmp_IAH18.nc IAH18.nc
elif [ $multipar == "n" ]
then
cdo -L -timavg -ifthen -gtc,0 tmp_IAH18.nc tmp_IAH18.nc IAH18.nc
else
echo "Average taken as default." 
cdo -L -timavg -ifthen -gtc,0 tmp_IAH18.nc tmp_IAH18.nc IAH18.nc
fi



echo ""
echo "Calculation: IAH 19"
# IAH 19: Days per month flow Q < Q95%
tmp_envs=$envs
while [ $tmp_envs -le $enve ]
do
echo ""
echo "Calculating year: $tmp_envs"
cdo -L -gt -selyear,$tmp_envs discharge_dailyTot_Environmental -timavg -selyear,$tmp_envs tmp_1y05.nc tmp_env05$tmp_envs.nc
let "tmp_envs = $tmp_envs + 1"
done
cdo mergetime tmp_env05* tmp_env_final.nc

tmp_alts=$alts
echo "Calculating the Altered Regime"
while [ $tmp_alts -le $alte ]
do
echo ""
echo "Calculating year: $tmp_alts"
cdo -L -gt -selyear,$tmp_alts discharge_dailyTot_BAU -timavg -selyear,$tmp_alts tmp_2y05.nc tmp_alt05$tmp_alts.nc
let "tmp_alts = $tmp_alts + 1"
done
cdo mergetime tmp_alt05* tmp_alt_final.nc

# IAH 19 Ratio
cdo -L -sub tmp_1.nc -mulc,0.2 -abs -sub -ymonavg -monsum tmp_alt_final.nc -ymonavg -monsum tmp_env_final.nc tmp_IAH19.nc
if [ $multipar == "y" ]
then
cdo -L -ifthen -gtc,0 tmp_IAH19.nc tmp_IAH19.nc IAH19.nc
elif [ $multipar == "n" ]
then
cdo -L -timavg -ifthen -gtc,0 tmp_IAH19.nc tmp_IAH19.nc IAH19.nc
else
echo "Average taken as default." 
cdo -L -timavg -ifthen -gtc,0 tmp_IAH19.nc tmp_IAH19.nc IAH19.nc
fi


# Remove excess files
rm tmp_alt*
rm tmp_env*

echo ""
read -p "Lower limit discharge for the average IAH output in m3/s: " variable1
echo "Creating a mask for all flows that have an extreme drought value above $variable1 m3/s."
# Create mask for rivers
cdo -L -ifthen -gtc,$variable1 tmp_1ya05.nc tmp_1.nc river_mask.nc

echo ""
echo "Calculating the average alteration factor."
# Average all IAHs
rm IAH_average.nc
cdo -L -timavg -ifthen river_mask.nc -ensavg IAH* IAH_average.nc

echo ""
echo "Indicators of Hydrologic Alteration completed"

# Remove all temporal files.
read -p "Remove all temporary files created for calculations (y/n):" variable2
if [ $variable2 == "y" ]
then 
rm tmp*
echo "removed temporary files."

elif [ $variable2 == "n" ]
then
echo "Temporary files not removed."

else
echo "False input, temporary files not removed; use: rm tmp* if you would like to remove all temporary files created"
fi
