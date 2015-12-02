; run the code in IDL 8.4
; note, there is NO spatial information in the output tif files
pro hdf2tif_mod44b_2 ;hdf2tif_mod44b_2 is the pro name, stored in local folder

; combine array before write out to tif
; only for h = 16:18, v = 8
wkdir = 'D:\users\Zhihua\MODIS\MOD44B'
data_loc = '\hdf'
output_loc = '\hdf2tif\'
;MOD44B, sds name
data_quality_sds_name = ['Percent_Tree_Cover', 'Percent_NonTree_Vegetation', 'Percent_NonVegetated', $
                     'Quality', 'Percent_Tree_Cover_SD', 'Percent_NonVegetated_SD', 'Cloud']

data_quality_Num = Size(data_quality_sds_name,/N_ELEMENTS)

;generate a year sequence
data_year = INDGEN(15, START = 2000, INCREMENT=1)

; set work directory to hdf folder
CD, wkdir + data_loc

;make a output directory
File_Mkdir, wkdir + output_loc

File_All = File_Search('*.hdf')

;print,File_All
Year_Num = Size(data_year,/N_ELEMENTS)

;start looping for each year
For  i = 0,Year_Num-1 Do Begin
File_idx = File_All[WHERE(STRMID(File_All, 8, 4) EQ data_year[i])] ; get file name within the same year
;print, file_idx

fileID = HDF_SD_Start(File_idx[1], /read) ;Open the file h = 16, v = 8 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree1; get Percent_Tree_Cover, as give it to Percent_tree1

fileID = HDF_SD_Start(File_idx[3], /read) ;Open the file h = 17, v = 8 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree2; get Percent_Tree_Cover, as give it to Percent_tree2

fileID = HDF_SD_Start(File_idx[5], /read) ;Open the file h = 18, v = 8 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree3; get Percent_Tree_Cover, as give it to Percent_tree3

Percent_tree_v8 = [Percent_tree1, Percent_tree2, Percent_tree3]

fileID = HDF_SD_Start(File_idx[0], /read) ;Open the file h = 16, v = 7 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree4; get Percent_Tree_Cover, as give it to Percent_tree1

fileID = HDF_SD_Start(File_idx[2], /read) ;Open the file h = 17, v = 7 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree5; get Percent_Tree_Cover, as give it to Percent_tree2

fileID = HDF_SD_Start(File_idx[4], /read) ;Open the file h = 18, v = 7 and assign it a file ID
HDF_SD_GetData, HDF_SD_Select(fileID, 0), Percent_tree6; get Percent_Tree_Cover, as give it to Percent_tree3

Percent_tree_v7 = [Percent_tree4, Percent_tree5, Percent_tree6]

Percent_tree = [[Percent_tree_v7], [Percent_tree_v8]]

;print, size(Percent_tree)
; define name and output to specific locations
output_name = STRMID(File_idx[1], 0, 12) + '.Percent_tree_cover.tif'
WRITE_TIFF, wkdir + output_loc + output_name, Percent_tree, COMPRESSION=1, /SHORT

; EndFor ; end for for band

print, 'finish calculating ' + string(i) + " of " + string(Year_Num) + ' files at ' + SYSTIME()

EndFor ; end for for file

end

