#bulk download landsat from glovis
## step one: select and save scene list
go to: http://glovis.usgs.gov/ --> Select Path/row number --> select file: download visable browse & metadata
--> save to a folder (e.g., ./p120024)

# in R3.1
setwd("./p122024")
scene.meta = list.files(path = ".", pattern = "*.meta")

#read into meta files, and extract cloud cover info
scene.id = c()
cloud.cover = c()
for (i in 1:length(scene.meta)){
  d <- scan(scene.meta[i], what=character() )
  scene.id = c(scene.id, d[3])
  cloud.cover = c(cloud.cover, as.numeric(d[18]))

}

scene.df = data.frame(scene_id = scene.id, cloud_cover = cloud.cover)
scene1.df <- scene.df[which(as.numeric(substr(scene.df$scene_id,10,13)) >= 2000 &   #select year
                             as.numeric(substr(scene.df$scene_id,14,16)) >= 106 &   #select doy
                             as.numeric(substr(scene.df$scene_id,14,16)) <= 290 & 
                             as.numeric(scene.df$cloud_cover) < 70),]

scene1.lc = scene1.df$scene_id[substr(scene1.df$scene_id,1,3) == "LC8"]
scene1.lt = scene1.df$scene_id[substr(scene1.df$scene_id,1,3) == "LT5"]
scene1.le_slc_on = scene1.df$scene_id[substr(scene1.df$scene_id,1,3) == "LE7" & as.numeric(substr(scene1.df$scene_id,10,16)) < 2003152]
scene1.le_slc_off = scene1.df$scene_id[substr(scene1.df$scene_id,1,3) == "LE7" & as.numeric(substr(scene1.df$scene_id,10,16)) > 2003152]

scene1.lc <- factor(scene1.lc)
scene1.lt <- factor(scene1.lt)
scene1.le_slc_on <- factor(scene1.le_slc_on)
scene1.le_slc_off <- factor(scene1.le_slc_off)


sink('p122024_since2000_2.txt') # starting write out into a text files

cat("GloVis Scene List","\n")
cat("sensor=Landsat 8 OLI","\n")
cat("ee_dataset_name=LANDSAT_8","\n")
for (i in 1:length(scene1.lc)){
  cat(levels(scene1.lc)[i],"\n")
}

cat("sensor=L7 SLC-off (2003->)","\n")
cat("ee_dataset_name=LANDSAT_ETM_SLC_OFF","\n")
for (i in 1:length(scene1.le_slc_off)){
  cat(levels(scene1.le_slc_off)[i],"\n")
}

cat("sensor=L7 SLC-on (1999-2003)","\n")
cat("ee_dataset_name=LANDSAT_ETM","\n")
for (i in 1:length(scene1.le_slc_on)){
  cat(levels(scene1.le_slc_on)[i],"\n")
}

cat("sensor=Landsat 4-5 TM","\n")
cat("ee_dataset_name=LANDSAT_TM","\n")
for (i in 1:length(scene1.lt)){
  cat(levels(scene1.lt)[i],"\n")
}

sink() # Stop writing to the file

# step two: submit scene list
go to https://espa.cr.usgs.gov/login/?next=/ --> username: liuzh811, password: xxxx 

# step three: download  using firefox download all app to download all the landsat images
go to http://www.downthemall.net/, download, install, and use the app
