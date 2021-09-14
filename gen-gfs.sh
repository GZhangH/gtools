#!/home/zhang/envs/rks/bin/python 

from matplotlib import pyplot as plt
import PySimpleGUI as sg
#import PySimpleGUIWeb as sg

from datetime import datetime, timedelta, timezone
import timezonefinder as tzf
import time
import pytz

from rocketpy import Environment

def sft(size=5, font='Monospace'):
    return (font, size)

def warnw():
    wlayout = [
        [
            sg.Text('Warning', font=sft(20), text_color='red')
        ]
    ]
    wapp = sg.Window(
        title='WARNING',layout=wlayout,
    )
    while True:
            we, wv = wapp.read(500)
            if we==sg.WINDOW_CLOSED or we=='Exit':
                break
    wapp.Close()

def gen_gfs(lat, lon, alt, ddate):
    ntz = tzf.TimezoneFinder().timezone_at(lng=lon, lat=lat)
    datein   = datetime(*ddate)
    datein   = datein.replace(tzinfo=pytz.timezone(ntz)).astimezone(pytz.utc)
    dateinfo = (datein.year, datein.month, datein.day, datein.hour, datein.minute)
    EnvGFS  = Environment(
        railLength = 5,
        longitude  = lon,
        latitude   = lat,
        elevation  = alt,
    )
    EnvGFS.setDate(dateinfo)
    try:
        EnvGFS.setAtmosphericModel(type="Forecast", file="GFS")
        winds = EnvGFS.windSpeed.source
        windd = EnvGFS.windDirection.source
        windv = EnvGFS.windVelocityY.source
        windu = EnvGFS.windVelocityX.source
        return (winds, windd, windv, windu)
    except:
        warnw()
    

layout = [
    [
        sg.Text('Global Forecast System', font=sft(20))
    ],
    [
        sg.Frame(
            layout=[
                
                [
                    sg.Text('Latitude  = ', font=sft(12)),
                    sg.Input(font=sft(12), size=(15,1), key='lat',
                             default_text=-34.9339390),
                ],
                [
                    sg.Text('Longitude = ', font=sft(12)),
                    sg.Input(font=sft(12), size=(15,1), key='lon',
                             default_text=135.6423867),
                ],
                [
                    sg.Text(' Altitude = ', font=sft(12)),
                    sg.Input(font=sft(12), size=(15,1), key='alt',
                             default_text=19.0),
                ],
            ],
            title='POSITION', font=sft(15)
        ),
        sg.Frame(
            layout=[
                [
                    sg.Input(font=sft(12), size=(6,1), key='year',
                             default_text=datetime.now().year),
                    sg.Text('year/ ', font=sft(12)),
                    sg.Input(font=sft(12), size=(3,1), key='month',
                             default_text=datetime.now().month),
                    sg.Text('month/ ', font=sft(12)),
                    sg.Input(font=sft(12), size=(3,1), key='day',
                             default_text=datetime.now().day),
                    sg.Text('day', font=sft(12)),
                ],
                [
                    sg.Spin(
                        values=[i for i in range(0, 24)],
                        size=(3, 1), font=sft(12), key='hour',
                        initial_value=datetime.now().hour
                    ),
                    sg.Text('hour: ', font=sft(12)),
                    sg.Spin(
                        values=[i for i in range(0, 60)],
                        size=(3, 1), font=sft(12), key='minute',
                        initial_value=datetime.now().minute
                    ),
                    sg.Text('minute', font=sft(12)),
                ],
            ],
            title='TIME', font=sft(15)
        )
    ],
    [
        sg.Button(button_text='Load Data', key='ldata',
                  font=sft(15), pad=(0,10),
                  button_color=('red')),
    ],
    [
        sg.Listbox(size=(20,20),values=[],
                   key='lbox', font=sft(10),
        ),
        sg.Output(size=(100,20),font=sft(8))
    ],
    [
        sg.Frame(
            layout=[[
                sg.Button(button_text='North/East Wind Speed',
                          key='plotv', font=sft(12)),
            #],[
                sg.Button(button_text='Wind Speed/Direction',
                          key='plotd', font=sft(12)),
            ],],
            title='PLOT', font=sft(15), element_justification='center'
        ),
    ],
]

wconfig = {
    'title': 'Generate GFS',
    'size': (1200,700),
    'layout':layout,
    'resizable':True,
    'element_justification': 'center',
}

app = sg.Window(**wconfig)

alld = []
albs = []

while True:

    event, value = app.read()
    #event, value = app.read(500)
    print(event, value)

    if event==sg.WINDOW_CLOSED or event=='Exit':
        break

    if event=='ldata':
        ddate = (
            int(value['year']), int(value['month']), int(value['day']),
            int(value['hour']), int(value['minute'])
        )
        ws, wd, wv, wu = gen_gfs(
            float(value['lat']),
            float(value['lon']),
            float(value['alt']),
            ddate
        )
        print("Data loctime = ",ddate)
        #app['ldata'].update(button_color='green')
        albs.append(ddate)
        app['lbox'].update(values=albs)
        alld.append([ws, wd, wv, wu])

    if event=='plotv' and value['lbox']!=[]:
        for fid in range(len(albs)):
            if albs[fid]==value['lbox'][0]:
                dd = albs[fid]
                ws = alld[fid][0] 
                wd = alld[fid][1] 
                wv = alld[fid][2] 
                wu = alld[fid][3] 
        
        fig, axes = plt.subplots(1,2,sharey=True,facecolor='w')
        axes[0].set_title("North wind")
        axes[1].set_title("East wind")
        fig.supxlabel("wind speed(m/s)")
        fig.supylabel("height(m)")
        fig.suptitle( datetime(*dd).strftime("%Y-%m-%d %H:%M") )
        axes[0].plot(
            wv[:,1],wv[:,0]
        )
        axes[1].plot(
            wu[:,1],wu[:,0]
        )
        for ax in axes:
            ax.grid(ls=':')
        plt.tight_layout(h_pad=0.0, w_pad=0.0)
        plt.show()

    if event=='plotd' and value['lbox']!=[]:
        for fid in range(len(albs)):
            if albs[fid]==value['lbox'][0]:
                dd = albs[fid]
                ws = alld[fid][0] 
                wd = alld[fid][1] 
                wv = alld[fid][2] 
                wu = alld[fid][3] 
        fig, axes = plt.subplots(1,2,sharey=True,facecolor='w')
        axes[0].set_title("Wind Speed")
        axes[1].set_title("Direction")
        axes[0].set_xlabel("wind speed(m/s)")
        axes[1].set_xlabel("direction(deg)")
        fig.supylabel("height(m)")
        fig.suptitle( datetime(*dd).strftime("%Y-%m-%d %H:%M") )
        axes[0].plot(
            ws[:,1],ws[:,0]
        )
        axes[1].plot(
            wd[:,1],wd[:,0]
        )
        for ax in axes:
            ax.grid(ls=':')
        plt.tight_layout(h_pad=0.0, w_pad=0.0)
        plt.show()

app.Close()
