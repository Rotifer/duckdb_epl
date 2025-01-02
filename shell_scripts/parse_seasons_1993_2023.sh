#!/usr/bin/bash

# Declare variables.
OUTPUT_DIR="../output_data/"
INPUT_DIR="../source_data/"

# Remove the final output file if it already exists.
if [[ -f ${OUTPUT_DIR}seasons_1993_2023.tsv ]]; then
  rm ${OUTPUT_DIR}seasons_1993_2023.tsv 
fi

# Parse the files which *do not have* the match time column.
for FILE in ${INPUT_DIR}{1993..2018}*.csv
do
  sed '1d' $FILE | \
    awk -v season=$(basename $FILE | sed 's/.csv//') -v null='NA' \
      'BEGIN{FS=","; OFS="\t"}{print season,$2,null,$3,$4,$5,$6}' \
         >>seasons_1993_2018.tsv
done

# Parse the files which *have* the match time column.
for FILE in ${INPUT_DIR}{2019..2023}*.csv
do
  sed '1d' $FILE | \
    awk -v season=$(basename $FILE | sed 's/.csv//') \
      'BEGIN{FS=","; OFS="\t"}{print season,$2,$3,$4,$5,$6,$7}' \
         >>seasons_2019_2024.tsv
done

# Write the column names header row to the final output file.
echo "season,match_date,match_time,home_club_name,\
        away_club_name,home_club_goals,away_club_goals" | \
     awk 'BEGIN{FS="," ; OFS="\t"}{print $1,$2,$3,$4,$5,$6,$7}' \
       >seasons_1993_2023.tsv

# Append the two files generated above to the output file.
cat seasons_1993_2018.tsv seasons_2019_2024.tsv \
      >>seasons_1993_2023.tsv

# Clean up by moving the main output file and by removing the temporary files.
mv seasons_1993_2023.tsv ${OUTPUT_DIR}
rm seasons_1993_2018.tsv
rm seasons_2019_2024.tsv
echo "Script finished, see file '${OUTPUT_DIR}seasons_1993_2023.tsv'"
