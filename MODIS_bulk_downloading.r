# section 1: downloading collection 5 using MODIS package
# need gdal utility, go to http://trac.osgeo.org/osgeo4w/ to download osgeo4w
##############################################################################
# downlaod MODIS MCD43A4 and MCD43A2 data
#load library
library("MODIS")
library(rgdal)
library(raster)

MODISoptions(localArcPath="D:\\users\\Zhihua\\MODIS",
             outDirPath="D:\\users\\Zhihua\\MODIS",
             gdalPath='c:/OSGeo4W64/bin')  # OSGeo4W64 installation directory

getProduct() # list available products

dates <- as.POSIXct( as.Date(c("1/1/2000","30/7/2015"),format = "%d/%m/%Y") )
dates2 <- transDate(dates[1],dates[2]) # Transform input dates from before
proj.geo = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "

product="MCD43A4"
collection = getCollection(product, collection=NULL, newest=TRUE, forceCheck=FALSE, as="character", quiet=TRUE)

#download reflectance
runGdal(product=product,  #Nadir BRDF-Adjusted Reflectance, 1000 m reso
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        tileH = 16:18,tileV = 7:8,
        SDSstring = "1", #only extract the first layers
        outProj=proj.geo,
        job = "NBAR")

#download QC
runGdal(product="MCD43A4",  #Nadir BRDF-Adjusted Reflectance, 1000 m reso
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        tileH = 16:18,tileV = 7:8,
        SDSstring = "1", #only extract the first layers
        outProj=proj.geo,
        job = "NBAR_QC")
        
        
# section 2: downloading MODIS NBAR products directly from MODIS data pool
# https://lpdaac.usgs.gov/data_access/data_pool
# the data format is hdf
# for example, downloading MCD43 v6 

# write a function to downloa  data
dlmcd43 <- function(product, #e.g., MCD43A2, MCD43A4
                    version, #e.g., 6
                    start_date, #yyyymmdd, e.g., "20051101"
                    end_date, #yyyymmdd, e.g., "20060401"
                    tileh, #e.g., c("17","18")
                    tilev, #e.g., c("07","08")
                    output_loc) #e.g., "MCD43A2V006"
  {
  
  require(XML)
  library(RCurl)
  
  #construct date first
  d31 = c(paste("0", 1:9, sep = ""), as.character(10:31))
  mon.leap = c(rep("01", 31),rep("02",29), rep("03",31),rep("04",30),rep("05",31),rep("06",30),
               rep("07",31),rep("08",31),rep("09",30),rep("10",31),rep("11",30),rep("12",31))
  day.leap = c(d31, d31[-c(30,31)], d31, d31[-31],d31,d31[-31],d31,d31,d31[-31],d31,d31[-31],d31)
  mod.date = data.frame(year = as.character(c(rep(2000, 366), rep(2001, 365),rep(2002, 365),rep(2003, 365),rep(2004, 366),
                                              rep(2005, 365),rep(2006, 365),rep(2007, 365),rep(2008, 366),
                                              rep(2009, 365),rep(2010, 365),rep(2011, 365),rep(2012, 366),
                                              rep(2013, 365),rep(2014, 365),rep(2015, 365),rep(2016, 366))),
                        month = c(mon.leap, mon.leap[-60],mon.leap[-60],mon.leap[-60],mon.leap,
                                  mon.leap[-60],mon.leap[-60],mon.leap[-60],mon.leap,
                                  mon.leap[-60],mon.leap[-60],mon.leap[-60],mon.leap,
                                  mon.leap[-60],mon.leap[-60],mon.leap[-60],mon.leap),
                        day = c(day.leap, day.leap[-60],day.leap[-60],day.leap[-60],day.leap,
                                day.leap[-60],day.leap[-60],day.leap[-60],day.leap,
                                day.leap[-60],day.leap[-60],day.leap[-60],day.leap,
                                day.leap[-60],day.leap[-60],day.leap[-60],day.leap))
  #get url
  url <- "http://e4ftl01.cr.usgs.gov/MOTA/"
  start_idx = which(mod.date$year == as.character(substr(start_date, 1, 4)) &
                    mod.date$month == as.character(substr(start_date, 5, 6)) &
                    mod.date$day == as.character(substr(start_date, 7, 8)))
 
  end_idx = which(mod.date$year == as.character(substr(end_date, 1, 4)) &
                      mod.date$month == as.character(substr(end_date, 5, 6)) &
                      mod.date$day == as.character(substr(end_date, 7, 8)))

  #create a folder to store hdf data

  dir.create(paste(getwd(),"/",output_loc, sep = ""))
  for (i in start_idx:end_idx){
    url1 <- paste(url, product, ".00",version,"/",
                  paste(mod.date$year[i],mod.date$month[i],mod.date$day[i], sep = "."),
                  "/", sep = "")
    doc <- htmlParse(url1)
    links <- xpathSApply(doc, "//a/@href")
    free(doc)
    for(j in 1:length(tileh)){      
      for(k in 1:length(tilev)){

        #only select h17v07/h17v08
        fn = links[which(substr(links, 18, 23) == paste("h",tileh[j],"v",tilev[k], sep = ""))]
        download.file(paste(url1, fn[1], sep = ""), 
                      destfile = paste(getwd(),"/",output_loc,"/", fn[1], sep = ""),
                      mode = "wb")
        
      } # end of k
    } #end if j
    print(paste("Finish downloading ", i - start_idx, "of", end_idx-start_idx, "of", product, " at ", format(Sys.time(), "%a %b %d %X %Y"), sep = " ") )

  } #end of i
}

setwd("D:/users/Zhihua/MODIS/NBARV006")
dlmcd43(product = "MCD43A4", 
        version = 6,
        start_date="20051101",
        end_date="20060401",
        tileh = "17",
        tilev = c("07","08"),
        output_loc = "MCD43A4")

#"MCD43A2"; data quality layers
dlmcd43(product = "MCD43A2", 
        version = 6,
        start_date="20051101",
        end_date="20060401",
        tileh = "17",
        tilev = c("07","08"),
        output_loc = "MCD43A2")

# section 3: downloading MODIS MOD44B (VCF) products directly from MODIS data pool

setwd("D:\\users\\Zhihua\\MODIS")
library(XML)
library(RCurl)

#construct date first
mod.date = c("2000.03.05", "2001.03.06","2002.03.06","2003.03.06","2004.03.05","2005.03.06","2006.03.06","2007.03.06",
             "2008.03.05","2009.03.06","2010.03.06","2011.03.06","2012.03.05","2013.03.06","2014.03.06")
tileh = c("16","17","18")
tilev = c("07","08")

#get url
url <- "http://e4ftl01.cr.usgs.gov/MOLT/"

for (i in 5:length(mod.date)){
  url1 <- paste(url, "MOD44B.051", "/",mod.date[i],"/", sep = "")
  doc <- htmlParse(url1)
  links <- xpathSApply(doc, "//a/@href")
  free(doc)
  for(j in 1:length(tileh)){      
    for(k in 1:length(tilev)){
      #only select h17v07/h17v08
      fn = links[which(substr(links, 17, 22) == paste("h",tileh[j],"v",tilev[k], sep = ""))]
      download.file(paste(url1, fn[1], sep = ""), 
                    destfile = paste(getwd(),"/","MOD44B","/", fn[1], sep = ""),
                    mode = "wb")
      
    } # end of k
  } #end if j
} #end of i

#change the hdf into raster files using IDL
# see hdf2tif.pro

###  5/5/2017, download data for fire/climate analysis
# downlaod MODIS MCD43A4 and MCD43A2 data

#load library

library("MODIS")
library(rgdal)
library(raster)

MODISoptions(localArcPath="C:/zhihua/modis_data",
             outDirPath="C:/zhihua/modis_data",
             gdalPath='C:/zhihua/OSGeo4W64/bin')  # OSGeo4W64 installation directory
			 

dates <- as.POSIXct( as.Date(c("1/1/2003","31/12/2015"),format = "%d/%m/%Y") )
dates2 <- transDate(dates[1],dates[2]) # Transform input dates from before
proj.geo = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "

# LST MYD11C3 
product="MYD11C3"
collection = getCollection(product, collection=NULL, newest=TRUE, forceCheck=FALSE, as="character", quiet=TRUE)

# get hdf first
getHdf(product = product, 
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY)
		
# get sds in the hdf file		
getSds(HdfName="C:/zhihua/modis_data/MODIS/MYD11C3.005/2003.01.01/MYD11C3.A2003001.005.2007274185043.hdf",method="gdal") # require GDAL (FWTools on Windows)

# extract data in hdf files
runGdal(product=product,  
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        # tileH = 16:18,tileV = 7:8,
        SDSstring = "110001100000001110", #
        outProj=proj.geo,
        job = "MYD11C3_LST")

		
# albedo MCD43C3 
product="MCD43C3"
collection = getCollection(product, collection=NULL, newest=TRUE, forceCheck=FALSE, as="character", quiet=TRUE)

# get hdf first
dates <- as.POSIXct( as.Date(c("1/1/2005","31/12/2015"),format = "%d/%m/%Y") )
dates2 <- transDate(dates[1],dates[2]) # Transform input dates from before

getHdf(product = product, 
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY)
		
runGdal(product=product,  #Nadir BRDF-Adjusted Reflectance, 1000 m reso
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        # tileH = 16:18,tileV = 7:8,
        SDSstring = "1", #only extract the first layers
        outProj=proj.geo,
        job = "MCD43C3_ALBEDO")


# VIs MYD13C2
library("MODIS")
library(rgdal)
library(raster)

MODISoptions(localArcPath="G:/modis_data",
             outDirPath="G:/modis_data",
             gdalPath='C:/OSGeo4W64/bin')  # OSGeo4W64 installation directory		 

dates <- as.POSIXct( as.Date(c("1/1/2003","31/12/2015"),format = "%d/%m/%Y") )
dates2 <- transDate(dates[1],dates[2]) # Transform input dates from before
proj.geo = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "

product="MYD13C2"
collection = getCollection(product, collection=NULL, newest=TRUE, forceCheck=FALSE, as="character", quiet=TRUE)
MODISoptions() # to get MODIS setup
# get hdf files
getHdf(product = product, 
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY)
	
runGdal(product=product,  #Nadir BRDF-Adjusted Reflectance, 1000 m reso
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        # tileH = 16:18,tileV = 7:8,
        SDSstring = "1", #only extract the first layers
        outProj=proj.geo,
        job = "MYD13C2_VI")

# Land cover MCD12C1	
product="MCD12C1"
collection = getCollection(product, collection=NULL, newest=TRUE, forceCheck=FALSE, as="character", quiet=TRUE)
# get hdf first
getHdf(product = product, 
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY)

runGdal(product=product,  #Nadir BRDF-Adjusted Reflectance, 1000 m reso
        collection = collection,
        begin=dates2$beginDOY,
        end = dates2$endDOY,
        # tileH = 16:18,tileV = 7:8,
        SDSstring = "1", #only extract the first layers
        outProj=proj.geo,
        job = "MCD12C1_LC")

# MODIS ET
# file want to download: files.ntsg.umt.edu/data/NTSG_Products/MOD16/MOD16A2_MONTHLY.MERRA_GMAO_1kmALB/GEOTIFF_0.05degree 

# see the document in the MODIS_ET to see how to download using wget
wget –l 0 –r –nH –np –I \
data/NTSG_Products/MOD16/MOD16A2_MONTHLY.MERRA_GMAO_1kmALB/GEOTIFF_0.05degree*, \
data/NTSG_Products/MOD16/MOD16A2_MONTHLY.MERRA_GMAO_1kmALB/GEOTIFF_0.05degree, \
–R *.html,*.htm files.ntsg.umt.edu/data/NTSG_Products/MOD16/MOD16A2_MONTHLY.MERRA_GMAO_1kmALB

# MODIS burned area
http://modis-fire.umd.edu/pages/BurnedArea.php?target=Download

# download MYD13C2 V6 directly from LP DAAC


workdir = "G:/modis_data"
setwd(workdir)
library(XML)
library(RCurl)

#construct date first
mod.year = c(2003:2015)
mod.md = c("01.01","02.01","03.01","04.01","05.01","06.01","07.01","08.01","09.01","10.01","11.01","12.01")
mod.date = paste(rep(mod.year, each = 12), rep(mod.md, 13), sep = ".")

#get url
url <- "https://e4ftl01.cr.usgs.gov/MOLA/"

# Reading information from a password protected site
# http://stackoverflow.com/questions/5420506/reading-information-from-a-password-protected-site
# http://stackoverflow.com/questions/6415798/how-to-access-a-web-service-that-requires-authetication
useid = "l*****11"
pw = "L**********16"

for (i in 1:length(mod.date)){

  url1 <- paste(url, "MYD13C2.006", "/",mod.date[i],"/", sep = "")
  doc <- getURI(url1)
  links = strsplit(doc, "href=\"")[[1]]
  # doc <- htmlParse(url1)
  # links <- xpathSApply(doc, "//a/@href")
  # free(doc)
  
  download.dir = paste(workdir, "/MODIS/MYD13C2.006", sep = "")
  dir.create(file.path(download.dir, mod.date[i]), showWarnings = FALSE)
 
#select files 
  fn = links[11]
  fn = strsplit(fn,"\">")[[1]][1]

  download.file(paste("http://", useid, ":", pw, "@", substr(url1,9,nchar(url1)), fn, sep = ""), #suppy usename and password
                    destfile = paste(download.dir,"/",mod.date[i],"/", fn, sep = ""),
                    method = "auto")
 
} #end of i




