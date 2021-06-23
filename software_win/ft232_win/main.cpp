#include <stdio.h>
#include <time.h>
#include "ftd2xx.h"
#include <iostream>


using namespace std;

int main(int argc, char** argv) 
{

    FT_HANDLE handle;

    // check how many FTDI devices are attached to this PC
    unsigned long deviceCount = 0;
    if (FT_CreateDeviceInfoList(&deviceCount) != FT_OK) {
        printf("Unable to query devices. Exiting.\r\n");
        return 1;
    }

    // get a list of information about each FTDI device
    FT_DEVICE_LIST_INFO_NODE* deviceInfo = (FT_DEVICE_LIST_INFO_NODE*)malloc(sizeof(FT_DEVICE_LIST_INFO_NODE) * deviceCount);
    if (FT_GetDeviceInfoList(deviceInfo, &deviceCount) != FT_OK) {
        printf("Unable to get the list of info. Exiting.\r\n");
        return 1;
    }

    // print the list of information
    for (unsigned long i = 0; i < deviceCount; i++) {

        printf("Device = %d\r\n", i);
        printf("Flags = 0x%X\r\n", deviceInfo[i].Flags);
        printf("Type = 0x%X\r\n", deviceInfo[i].Type);
        printf("ID = 0x%X\r\n", deviceInfo[i].ID);
        printf("LocId = 0x%X\r\n", deviceInfo[i].LocId);
        printf("SN = %s\r\n", deviceInfo[i].SerialNumber);
        printf("Description = %s\r\n", deviceInfo[i].Description);
        printf("Handle = 0x%X\r\n", deviceInfo[i].ftHandle);
        printf("\r\n");

        // connect to the device with SN "FT3SSN2O"
        if (strcmp(deviceInfo[i].Description, "3DP200") == 0) {

            if (FT_OpenEx(deviceInfo[i].SerialNumber, FT_OPEN_BY_SERIAL_NUMBER, &handle) == FT_OK &&
                FT_SetBitMode(handle, 0xFF, 0x40) == FT_OK &&
                FT_SetLatencyTimer(handle, 2) == FT_OK &&
                FT_SetUSBParameters(handle, 65536, 65536) == FT_OK &&
                FT_SetFlowControl(handle, FT_FLOW_RTS_CTS, 0, 0) == FT_OK &&
 //               FT_Purge(handle, FT_PURGE_RX | FT_PURGE_TX) == FT_OK &&
                FT_Purge(handle, FT_PURGE_TX) == FT_OK &&
                FT_SetTimeouts(handle, 1000, 1000) == FT_OK) {

                // connected and configured successfully
                // read 1GB of data from the FTDI/FPGA
                char rxBuffer[64] = { 0 };
                char txBuffer[65536] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#%";
                unsigned long byteCount = 0;
                char temp[10];
                time_t startTime = clock();
                /*
                for (int i = 0; i < 3200; i++) {
                   if (FT_Read(handle, rxBuffer, 65536, &byteCount) != FT_OK || byteCount != 65536) {
                        printf("Error while reading from the device. Exiting.\r\n");
                        return 1;
                    }
                }
                */
                /*
                for (int i = 0; i < 3200; i++) {
                    if (FT_Write(handle, txBuffer, 64, &byteCount) != FT_OK || byteCount != 64) { printf("TX Error.\r\n"); return 1; }
                    if (FT_Read(handle, rxBuffer, 64, &byteCount) != FT_OK || byteCount != 64) { printf("RX Error.\r\n"); return 1; }
                }
                time_t stopTime = clock();
                double secondsElapsed = (double)(stopTime - startTime) / CLOCKS_PER_SEC;
                double mbps = 8589.934592 / secondsElapsed * 0.1953125;
                printf("Read 1GB from the FTDI in %0.1f seconds.\r\n", secondsElapsed);
                printf("Average read speed: %0.1f Mbps.\r\n", mbps);
                */
                while (1)
                {
                    printf("发送给USB的数据：");
                    cin >> txBuffer;
                    if (FT_Write(handle, txBuffer, 64, &byteCount) != FT_OK || byteCount != 64){printf("TX Error.\r\n");return 1;}
                    if (FT_Read(handle, rxBuffer, 64, &byteCount) != FT_OK || byteCount != 64) { printf("RX Error.\r\n"); return 1; }
                    printf("USB传回来的数据：%s\r\n", rxBuffer);
                }
                return 0;
            }
            else {
                // unable to connect or configure
                printf("Unable to connect to or configure the device. Exiting.\r\n");
                return 1;
            }
        }
    }
    return 0;
}

