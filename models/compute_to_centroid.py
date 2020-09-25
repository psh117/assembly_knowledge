import open3d
import glob
import numpy as np

INPUT_PLY_PATH = './ply/*'
OUTPUT_PLY_PATH = './ply_centered/'

input_ply_paths = glob.glob(INPUT_PLY_PATH)

for input_ply_path in input_ply_paths:
    cloud = open3d.io.read_point_cloud(input_ply_path)
    centroid = cloud.get_center()
    np.save(OUTPUT_PLY_PATH + input_ply_path.split('/')[-1][:-4] + '_centroid.npy', centroid)
    
