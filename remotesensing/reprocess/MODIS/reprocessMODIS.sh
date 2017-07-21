#!/bin/sh

set -x

###
# process_MODIS
###
reprocess_MODIS() {
        if [ $# -lt 4 ]; then
                echo "usage: process_MODIS <master>, <sectorDir>, <sectorName>, <file>"
                echo "Example: process_MODIS Master1km.AKAP , AKAP, 1kmAKAP, /data/AVHRR/gina/n19.13139.1928.avhrr.gz "
                return 1
        fi

        MASTER=/data/MASTERS/$1
        SECTOR_DIR=$2 # AKAP
        SECTOR_NAME=$3 # 1kmAKAP
        FILE=$4 # with path
        FILE_NAME=`basename $4`
	
	if [ $FILE_NAME = 't1.17005.2119.modis_cal.tdf.250mAKBO.reg' ]; then
		return
	fi
	
	if [ $FILE_NAME = 't1.17005.2257.modis_cal.tdf.250mAKBO.reg' ]; then
		return
	fi

	if [ `echo $FILE_NAME | grep 'modis_cal.tdf'` ]; then 
		return
	fi

        PNG_DIR=/data/reprocess/MODIS/png/$SECTOR_DIR
        if [ ! -d $PNG_DIR ]; then
                mkdir -p $PNG_DIR
        fi

        TMP_DIR=/data/MODIS/tmp

        cp $FILE $TMP_DIR

	coast \
		master_file="$MASTER" \
		reduce_factor=1 \
		coast_file="wvsplus.coast dcw.states dcw.political" \
		$TMP_DIR/${FILE_NAME}.coast

	###
	# TIR
	###
	imscale \
		master_file="$MASTER" \
		include_vars=modis_ch31b_temp \
		est_range=n \
		image_colors=216 \
		max_width=1280 \
		max_height=1024 \
		fixed_size=no \
		zoom_factor=1 \
		real_resample=yes \
		min_value=-65 \
		max_value=35 \
		invert_scale=no \
		north_up=no \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.TIR.byte 

	legend \
		master_file="$MASTER" \
		line_1="\%pass_date  \%start_time UTC \%satellite thermal infrared brightness temperature (C)" \
		line_2="" \
		sample_offset=0 \
		text_height=16 \
		text_type=bold \
		line_offset=756 \
		full_width=y \
		outline=n \
		center_text=y \
		solid_bg=y \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.TIR.legend 

	wedge \
		master_file="$MASTER" \
		wedge_lines=25 \
		wedge_samples=1000 \
		wedge_dir=right \
		text_height=16 \
		text_type=bold \
		two_color_text=y \
		line_offset=775 \
		sample_offset=0 \
		scale_min=-65 \
		scale_max=35 \
		invert_scale=no \
		label_base=-65 \
		label_step=10 \
		discrete_steps=n \
		outline=n \
		$TMP_DIR/${FILE_NAME}.TIR.wedge 

	xinject \
		master_file="$MASTER" \
		bg_var_name=modis_ch31b_temp \
		colors_per=2 \
		meta_colors="240 241 242 243 244 245" \
		line_widths="1 1 1" \
		line_types="solid solid solid" \
		marker_types="+ + +" \
		marker_sizes="15 15 15" \
		image_colors=216 \
		$TMP_DIR/${FILE_NAME}.TIR.byte $TMP_DIR/${FILE_NAME}.coast $TMP_DIR/${FILE_NAME}.TIR.wedge $TMP_DIR/${FILE_NAME}.TIR.legend $TMP_DIR/${FILE_NAME}.TIR.inject

	expim \
		master_file="$MASTER" \
		image_format=png \
		image_var=modis_ch31b_temp \
		image_colors=216 \
		color_palette=white-black \
		draw_indexes="240 241 242 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod goldenrod black" \
		$TMP_DIR/${FILE_NAME}.TIR.inject $PNG_DIR/${FILE_NAME}.TIR.png

	###
	# ASH
	###
	imscale \
		master_file="$MASTER" \
		include_vars=31m32 \
		est_range=n \
		image_colors=216 \
		max_width=1280 \
		max_height=1024 \
		fixed_size=no \
		zoom_factor=1 \
		real_resample=yes \
		min_value=-6 \
		max_value=5 \
		invert_scale=no \
		north_up=no \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.ASH.byte

	legend \
		master_file="$MASTER" \
		line_1="\%pass_date  \%start_time UTC \%satellite thermal infrared brightness temperature difference (C)" \
		line_2="" \
		sample_offset=0 \
		text_height=16 \
		text_type=bold \
		line_offset=756 \
		full_width=y \
		outline=n \
		center_text=y \
		solid_bg=y \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.ASH.legend

	wedge \
		master_file="$MASTER" \
		wedge_lines=25 \
		wedge_samples=1000 \
		wedge_dir=right \
		text_height=16 \
		text_type=bold \
		two_color_text=y \
		line_offset=775 \
		sample_offset=0 \
		scale_min=-6 \
		scale_max=5\
		invert_scale=no \
		label_base=-6 \
		label_step=1 \
		discrete_steps=n \
		outline=n \
		$TMP_DIR/${FILE_NAME}.ASH.wedge

	xinject \
		master_file="$MASTER" \
		bg_var_name=31m32 \
		colors_per=2 \
		meta_colors="240 241 242 243 244 245" \
		line_widths="1 1 1" \
		line_types="solid solid solid" \
		marker_types="+ + +" \
		marker_sizes="15 15 15" \
		image_colors=216 \
		$TMP_DIR/${FILE_NAME}.ASH.byte $TMP_DIR/${FILE_NAME}.coast $TMP_DIR/${FILE_NAME}.ASH.wedge $TMP_DIR/${FILE_NAME}.ASH.legend $TMP_DIR/${FILE_NAME}.ASH.inject

	expim \
		master_file="$MASTER" \
		image_format=png \
		image_var=31m32 \
		image_colors=216 \
		color_palette=split_window \
		draw_indexes="240 241 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod black" \
		$TMP_DIR/${FILE_NAME}.ASH.inject $PNG_DIR/${FILE_NAME}.ASH.png

	###
	# MIR
	###
	imscale \
		master_file="$MASTER" \
		include_vars=modis_ch20b_temp \
		est_range=n \
		image_colors=216 \
		max_width=1280 \
		max_height=1024 \
		fixed_size=no \
		zoom_factor=1 \
		real_resample=yes \
		min_value=-50 \
		max_value=50 \
		invert_scale=no \
		north_up=no \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.MIR.byte

	legend \
		master_file="$MASTER" \
		line_1="\%pass_date  \%start_time UTC \%satellite mid-infrared brightness temperature (C)" \
		line_2="" \
		sample_offset=0 \
		text_height=16 \
		text_type=bold \
		line_offset=756 \
		full_width=y \
		outline=n \
		center_text=y \
		solid_bg=y \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.MIR.legend

	wedge \
		master_file="$MASTER" \
		wedge_lines=25 \
		wedge_samples=1000 \
		wedge_dir=right \
		text_height=16 \
		text_type=bold \
		two_color_text=y \
		line_offset=775 \
		sample_offset=0 \
		scale_min=-50 \
		scale_max=50 \
		invert_scale=no \
		label_base=-50 \
		label_step=10 \
		discrete_steps=n \
		outline=n \
		$TMP_DIR/${FILE_NAME}.MIR.wedge

	xinject \
		master_file="$MASTER" \
		bg_var_name=modis_ch20b_temp \
		colors_per=2 \
		meta_colors="240 241 242 243 244 245" \
		line_widths="1 1 1" \
		line_types="solid solid solid" \
		marker_types="+ + +" \
		marker_sizes="15 15 15" \
		image_colors=216 \
		$TMP_DIR/${FILE_NAME}.MIR.byte $TMP_DIR/${FILE_NAME}.coast $TMP_DIR/${FILE_NAME}.MIR.wedge $TMP_DIR/${FILE_NAME}.MIR.legend $TMP_DIR/${FILE_NAME}.MIR.inject

	expim \
		master_file="$MASTER" \
		image_format=png \
		image_var=modis_ch20b_temp \
		image_colors=216 \
		color_palette=black-white \
		draw_indexes="240 241 242 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod goldenrod black" \
		$TMP_DIR/${FILE_NAME}.MIR.inject $PNG_DIR/${FILE_NAME}.MIR.png

	###
	# VIS
	###
	legend \
		master_file="$MASTER" \
		line_1="\%pass_date  \%start_time UTC \%satellite visible reflectance (percent)" \
		line_2="" \
		sample_offset=0 \
		text_height=16 \
		text_type=bold \
		line_offset=756 \
		full_width=y \
		outline=n \
		center_text=y \
		solid_bg=y \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.VIS.legend

	wedge \
		master_file="$MASTER" \
		wedge_lines=25 \
		wedge_samples=1000 \
		wedge_dir=right \
		text_height=16 \
		text_type=bold \
		two_color_text=y \
		line_offset=775 \
		sample_offset=0 \
		scale_min=0 \
		scale_max=100\
		invert_scale=no \
		label_base=0 \
		label_step=10 \
		discrete_steps=n \
		outline=n \
		$TMP_DIR/${FILE_NAME}.VIS.wedge
}

dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKAL
export SECTOR=AKAL
./collectFiles.sh
for file in `./collectFiles.sh`; do
        reprocess_MODIS "Master2km.AKAL" "AKAL" "2kmAKAL" "$file"
done

dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKBO
export SECTOR=AKBO
./collectFiles.sh
for file in `./collectFiles.sh`; do
        reprocess_MODIS "Master250m.AKBO" "AKBO" "250mAKBO" "$file"
done

dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKEA
export SECTOR=AKEA
./collectFiles.sh
for file in `./collectFiles.sh`; do
        reprocess_MODIS "Master1km.AKEA" "AKEA" "1kmAKEA" "$file"
done

