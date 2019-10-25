
# Dynamic clamp controller
 25/10/2019
**Kyle Wedgwood**

This repository contains files to run a lightweight GUI for uploading
parameters to the excellent Arduino and Teensy-based dynamic clamp
 (https://www.eneuro.org/content/4/5/ENEURO.0250-17.2017). My hope is
that the software is straightforward to use and these notes are are kept
only for reference.

# Software
Developed and tested on MATLABR2018a. Please let me know if you
experience any bugs on a different version of Matlab.

## Installation
To install, simply clone the repository into your folder of choice. No
additional steps are necessary.

## Setting up
The only thing you need to change in the code is the COMPort in line
148. This should be set to the COM port number that the Teensy is on.
This will be the same as the COM port as the one displayed in the
Arduino software when you are uploading the sketches to the Teensy. *In
later versions, I plan to edit this so that the COM port can be set in
the settings window.*

## Running
To start the GUI, simply run the file DynamicClampController.

## Closing
To stop using the GUI, simply close the window. The program will
automatically stop communicating with the Teensy.

## Important
If you switch sketches whilst the GUI running, make sure that you reset
the Teensy *before* loading the appropriate parameter file or
configuring a new one. Resetting the Teensy will interrupt the
communication over the serial port. Loading a parameter file or
configuring a new one will reopen the serial port fresh. If you fail to
do this, an error will occur when you attempt to transmit values to the
Teensy.

# Using the GUI
There are three main windows in the GUI: the main window, the
configuration window and the settings window. When actually using the
GUI to control the Teensy, only the main window should be open. If you are using the controller for the first time, you will need to open the configuration window to set up the parameter configuration.

## Main window
![alt text][main]

[main]: https://github.com/kyle-wedgwood/DynamicClampController/blob/master/Figs/DynamicClampController.png "Main window"

The main window displays the current parameter values, their minimum and
maximum value and buttons to upload, save and load parameters.

Each row of parameters contains (in order), the parameter name (this
does not have to match exactly the name in the Arduino sketch), the
minimum value, the set value and the maximum value. Trying to set values
outside of the allowed range for that parameter will cause the program
to display an error message.

* Load

Opens a window to load a parameter configuration file and resets the
connection to the Teensy

* Configure

Opens a window to configure the parameter set, including minimum,
maximum and default values.

* Save

Opens a window to save the current parameter values.

* Upload

Uploads the set value to the Teensy and saves the parameters to the file
*last_used_parameters.mat*.

* Last

Restores the last used parameter settings (loaded from
*last_used_parameters.mat*.

* Zero

Sets all of the parameters to 0 and uploads to the Teensy. This does
**not** overwrite the *last_used_parameters.mat* file.

* Preferences icon

Opens a window to change settings (currently only the fontsize can be
changed).

## Configuration window
![alt text][main]

[main]: https://github.com/kyle-wedgwood/DynamicClampController/blob/master/Figs/Configuration.png "Configuration window"

The configuration window facilitates the creation of parameter sets to
be controlled by the main window. Here, you can set the names of the
parameters as well as their allowed range.

Please note that the *names* of the parameters do **not** have to match the
Arduino sketch, but the *order* in which they appear **must.**

* (+) button

Adds a row for an additional parameter.

* (-) button

Removes the last parameter row.

* Save

Opens a window to save the parameter configuration. After saving, these parameters and limits will be loaded in the main window and the configuration window will close.

* Cancel

Closes the configuration window without changing parameter configuration.

## Preferences window

![alt text][main]

[main]: https://github.com/kyle-wedgwood/DynamicClampController/blob/master/Preferences.png "Preferences window"


The settings window allows users to change settings associated with the
DynamicClampController. Note that the settings do not change the way in
which the controller interacts with the Teensy.

# Feedback
If you would like to report a bug or make a feature request, please email me at k.c.a.wedgwood@exeter.ac.uk

