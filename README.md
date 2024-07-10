# AEM-Lk-v2

## Automation of Kinetic Inductance Extraction of MKID Simulations.

This repository is the updated version of AEM Lk. 
**AEM Lk** is a MATLAB app developed between Maynooth University and the Dublin Institute for Advanced Studies. If any of the original scripts in this repository are used in scientific publications, please cite the original author (See citation.cff). 

**AEM Lk** automates the extraction of Lk values of MKID pixels for a given set of Sonnet geometry files and measured resonant frequencies using MATLAB, the EM simulation software: Sonnet and the MATLAB Toolbox SonnetLab. This is done by varying the kinetic inductance value (*H/sq) in the Sonnet geometry files and matching the simulated resonance to the measured resonance as close as possible.
AEM Lk can extract Lk values to an accuracy of +/-0.001 *H/sq. It is important to note as well that the extract Lk values are only estimates and will include effects that influence the resonant frequency of the pixel (i.e. fabrication inaccuracies, dirt on the pixel, etc) 

**Important To Note:** The SonnetLab Toolbox scripts included here are slightly edited in order to work with the author’s settings and the latest versions of Sonnet. The edits made are as follows:



### **Important Steps Before Using AEM Lk**
Before using AEM Lk, it is necessary to follow the steps below:

1. In MATLAB, set your current path to the same folder that contains the Sonnet geometry files.
2. Make sure to include the AEM Lk scripts, SonnetLab Toolbox scripts and intersection scripts in your current path.
3. In the Sonnet Job Queue window, set the job queue to Auto Run.
4. In each Sonnet geometry file, make sure the output of the data file(i.e. csv file) is in the project folder (same folder as the geometry file).

### **Recommended Sonnet Settings**
Since individual MKID pixels typically include a single dip in the S21 parameter dictated by the resonant frequency and quality factor of the pixel, it is recommended to extract these values as accurate as possible within the simulation software (Sonnet). 
As such, the following are recommended settings used in Sonnet for MKID simulations:
In *EM Options* > *Advanced Options*
**Check;** *De-Embbed*, *Enhanced Resonance Detection*, *Q-Factor Accuracy*

### **How to Use AEM Lk**
AEM Lk is very simple to use and requires; Sonnet geometry files, Measured resonant frequencies and a input txt file.
1. Open the AEM Lk app in MATLAB.
![Uploading 255122604-e65fb3dc-20e8-4830-a4d6-30b5bbd0b54d.png…]()

2. Create a .txt file that contains a list of the **original Sonnet project filenames** and the measured resonant frequencies in the form of the following:
   ![txtfile](https://github.com/scathalmca/AEM-Lk/assets/92909628/22976773-c246-4f27-8f15-710388fc0cf1)
3. The Sonnet Files list should contain all the Sonnet geometry file names that will be used
4. The Measured Resonances list should contain all the Measured resonant frequencies obtained during characterisation of the MKID pixel(s).
5. Import the txt file into AEM Lk.
6. Select the accuracy of the Lk value to be extracted.
7. Start automation.

### **Operation**
AEM Lk will initially begin by simulating the original Sonnet files in order to find a starting point for the automation.
Once finished, AEM Lk will start with a single geometry and vary the Lk value to the accuracy set by the user until it achieves the closest simulated resonant frequency to the measured resonance imported by the user.
The script will then repeat this process for every initial geometry file.
All data extraction is performed via a .csv file produced by Sonnet. If the data is correct (read below), the resonant frequency of the structure is found with the minimum of the S21 parameter. The quality factor (Q<sub>Total</sub>  = Q<sub>C</sub> ) is found with the Full-Width Half-Maximum of the curve.
All data will be written to a txt file called “Kinetic Inductance Data.txt” and the geometry files with the corresponding extracted Lk values will be moved to the “Finished Geometries” Folder. All other projects simulated will be moved to the “Excess Geometries” Folder.
The final txt file will contain the following parameters:

![AEM LK Finished Txt File](https://github.com/scathalmca/AEM-Lk-v2/assets/92909628/841f1fcb-bf28-4fcf-9a1e-5e9c956c9755)

### **Correcting Data**
AEM Lk contains two main analysis scripts (*Auto_Sim* and *Auto_Extract*) that facilitate simulation, data analysis and error catching. Sonnet’s output files (.csv files) can contain some non-physical values that must be identified during automation. These errors include; |S21| above 1, the S21 parameter “falling off” after resonance, no resonance found in the frequency sweep etc. 
This errors are typically caught by AEM Lk and are corrected by either varying the frequency sweep range or removing data points. In the case of removing data points, this only occurs in the  |S21|>1 case and has shown no effect on resonant frequency or quality factor of the simulation. 

The .zip found in this repository contain scripts from the following:

**SonnetLab Toolbox:** https://www.sonnetsoftware.com/support/sonnet-suites/sonnetlab.html

**Intersections:** Douglas Schwarz (2024). Fast and Robust Curve Intersections (https://www.mathworks.com/matlabcentral/fileexchange/11837-fast-and-robust-curve-intersections), MATLAB Central File Exchange. Retrieved July 10, 2024.

