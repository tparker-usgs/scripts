#!/bin/sh

reprocess_AVHRR() {
	if [ $# -lt 4 ]; then
		echo "usage: process_AVHRR <master> <sectorDir> <sectorName> <file>"
		echo "Example: process_AVHRR Master1km.AKAP  AKAP 1kmAKAP /data/AVHRR/gina/n19.13139.1928.avhrr.gz "
		return 1
	fi

	MASTER=/data/MASTERS/$1
	SECTOR_DIR=$2 # AKAP
	SECTOR_NAME=$3 # 1kmAKAP
	FILE=$4 # with path
	#FILE_NAME=`basename $4`.$SECTOR_NAME
	FILE_NAME=`basename $4`

	PNG_DIR=/data/reprocess/AVHRR/png/$SECTOR_DIR
	if [ ! -d $PNG_DIR ]; then
		mkdir -p $PNG_DIR
	fi

	TMP_DIR=/data/reprocess/tmp
	if [ ! -d $TMP_DIR ]; then
		mkdir -p $TMP_DIR
	fi

	coast \
		master_file="$MASTER" \
		reduce_factor=1 \
		coast_file="wvsplus.coast dcw.states dcw.political" \
		$TMP_DIR/${FILE_NAME}.coast

	cp $FILE $TMP_DIR

	###
	# ASH
	###
	imscale \
		master_file="$MASTER" \
		include_vars=4m5 \
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
		bg_var_name=4m5 \
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
		image_var=4m5 \
		image_colors=216 \
		color_palette=split_window \
		draw_indexes="240 241 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod black" \
		$TMP_DIR/${FILE_NAME}.ASH.inject $PNG_DIR/${FILE_NAME}.ASH.png

	###
	# TIR
	###
	imscale \
		master_file="$MASTER" \
		include_vars=avhrr_ch4 \
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
		bg_var_name=avhrr_ch4 \
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
		image_var=avhrr_ch4 \
		image_colors=216 \
		color_palette=white-black \
		draw_indexes="240 241 242 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod goldenrod black" \
		$TMP_DIR/${FILE_NAME}.TIR.inject $PNG_DIR/${FILE_NAME}.TIR.png

	###
	# MIR
	##
	imscale \
		master_file="$MASTER" \
		include_vars=avhrr_ch3 \
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
		bg_var_name=avhrr_ch3 \
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
		image_var=avhrr_ch3 \
		image_colors=216 \
		color_palette=black-white \
		draw_indexes="240 241 242 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod goldenrod black" \
		$TMP_DIR/${FILE_NAME}.MIR.inject $PNG_DIR/${FILE_NAME}.MIR.png

	###
	# VIS
	###
	imscale \
		master_file="$MASTER" \
		include_vars=avhrr_ch1 \
		est_range=n \
		image_colors=216 \
		max_width=1280 \
		max_height=1024 \
		fixed_size=no \
		zoom_factor=1 \
		real_resample=yes \
		min_value=0 \
		max_value=100 \
		invert_scale=no \
		north_up=no \
		$TMP_DIR/${FILE_NAME} $TMP_DIR/${FILE_NAME}.VIS.byte

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

	xinject \
		master_file="$MASTER" \
		bg_var_name=avhrr_ch1 \
		colors_per=2 \
		meta_colors="240 241 242 243 244 245" \
		line_widths="1 1 1" \
		line_types="solid solid solid" \
		marker_types="+ + +" \
		marker_sizes="15 15 15" \
		image_colors=216 \
		$TMP_DIR/${FILE_NAME}.VIS.byte $TMP_DIR/${FILE_NAME}.coast $TMP_DIR/${FILE_NAME}.VIS.wedge $TMP_DIR/${FILE_NAME}.VIS.legend $TMP_DIR/${FILE_NAME}.VIS.inject 

	expim \
		master_file="$MASTER" \
		image_format=png \
		image_var=avhrr_ch1 \
		image_colors=216 \
		color_palette=black-white \
		draw_indexes="240 241 242 243 244 245" \
		draw_names="goldenrod goldenrod black goldenrod goldenrod black" \
		$TMP_DIR/${FILE_NAME}.VIS.inject $PNG_DIR/${FILE_NAME}.VIS.png
}

#dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKAL
#export SECTOR=AKAL
#./collectFiles.sh
#for file in `./collectFiles.sh`; do
	#reprocess_AVHRR "Master2km.AKAL" "AKAL" "2kmAKAL" "$file"
#done

dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKBO
export SECTOR=AKBO
./collectFiles.sh
for file in `./collectFiles.sh`; do
	reprocess_AVHRR "Master250m.AKBO" "AKBO" "250mAKBO" "$file"
done

dir=/data/erupt/Bogoslof2017/AVHRR/tdf/AKEA
export SECTOR=AKEA
./collectFiles.sh
for file in `./collectFiles.sh`; do
	reprocess_AVHRR "Master1km.AKEA" "AKEA" "1kmAKEA" "$file"
done
