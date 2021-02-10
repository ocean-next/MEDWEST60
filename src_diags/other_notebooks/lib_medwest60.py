#!/usr/bin/env  python
#=======================================================================
"""
StepHANIE Leroux
Collection of my "customed" tools related to  MEDWEST60 analysis...
"""
#=======================================================================


## standart libraries
import os,sys
import numpy as np

from scipy.signal import argrelmax
from scipy.stats import linregress

# xarray
import xarray as xr

# plot
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
from matplotlib.colors import Colormap
import matplotlib.colors as mcolors
import matplotlib.dates as mdates
import matplotlib.cm as cm
import matplotlib.dates as mdates
import matplotlib.ticker as mticker
from matplotlib.colors import from_levels_and_colors
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
#import cmocean


# custom tools
import lib_medwest60



def readmedwestens_1mb(machine='LAP', diriprefix='/Users/leroux/DATA/MEDWEST60_DATA/',
                       CONFIGCASEmed='MEDWEST60-GSL14',
                       ens='ens01',
                       mb='001',
                       CONFIGCASEref='MEDWEST60-GSL14',
                       typ="gridT-2D",
                       varna='sosstsst',
                       maskfile   ='/Users/leroux/DATA/MEDWEST60_DATA/MEDWEST60-I/MEDWEST60_mask.nc4',
                       maskvar     ='tmask'):

    '''
    Goal: read data from one ensemble member.
    Parameters...
    Returns:  nav_lat,nav_lon,bathy,data,varname,latexvarname
    '''
    
    diriprefix,maskfile,bathyfile = definepathsonmachine(machine)        
    

    dirimed = diriprefix+CONFIGCASEmed+"-S/"+ens+"/1h/"+typ+"/"
    print(dirimed)
    #diriref = diriprefixref+typ+"/"+"tmp/"  

    filiprefix = mb+CONFIGCASEmed+"-"+ens+"_1h_*"+typ+"_"
    print(filiprefix+"*.nc")
   
    mask =  xr.open_dataset(maskfile)[maskvar]
    # longitude
    nav_lon = xr.open_dataset(maskfile)['nav_lon']
    # latitude
    nav_lat = xr.open_dataset(maskfile)['nav_lat']
    
    data   = xr.open_mfdataset(dirimed+filiprefix+"*.nc",concat_dim='time_counter',decode_times=True)[varna]
        
    varname,latexvarname = flatexvarname(varna)
    
    return nav_lat,nav_lon,mask,data,varname,latexvarname


def readallmbs(machine='LAP', diriprefix='/Users/leroux/DATA/MEDWEST60_DATA/',
                       CONFIGCASEmed='MEDWEST60-GSL14',
                       ens='ens01',
                       mb='001',
                       CONFIGCASEref='MEDWEST60-GSL14',
                       typ="gridT-2D",
                       varna='sosstsst',
                       maskfile   ='/Users/leroux/DATA/MEDWEST60_DATA/MEDWEST60-I/MEDWEST60_mask.nc4',
                       maskvar     ='tmask',
                       NMBtot=1):

    ie=1

    for ie in range(1,NMBtot+1):

        if ie<10:
            mbn="00"+str(ie)
        if ie>9:
            mbn="0"+str(ie)

        nav_lat,nav_lon,mask,tmpMB,varname,latexvarname = readmedwestens_1mb(machine,typ=typ, mb=mbn,varna=varna,CONFIGCASEmed=CONFIGCASEmed,ens=ens,CONFIGCASEref=CONFIGCASEref,diriprefix=diriprefix,maskfile=maskfile,maskvar=maskvar)

        if (ie!=1):
            concdata = xr.concat([concdata,tmpMB], dim='e')
        else:
            concdata = tmpMB
    return nav_lat,nav_lon,mask,concdata,varname,latexvarname 



def readonlybathy(machine):

    diriprefix,maskfile,bathyfile = definepathsonmachine(machine)
    
    bathy =  xr.open_dataset(bathyfile)["Bathymetry"]
    # longitude
    nav_lon = xr.open_dataset(bathyfile)['nav_lon']
    # latitude
    nav_lat = xr.open_dataset(bathyfile)['nav_lat']
    
    return nav_lat,nav_lon,bathy
    
    
    
    

def plotmapMEDWEST(fig1,ehonan,nav_lon,nav_lat,cmap,norm,plto='tmp_plot',typlo='pcolormesh',coastL=False,coastC=False,coastLand=False,xlim=(0,10), ylim=(0,10),su='b',so='k',loncentr=0.,latcentr=0.,labelplt="",incrgridlon=5,incrgridlat=5,edgcol1='#585858',edgcol2='w',mk="o",mks=0.1,scattcmap=True,scattco='k'):

        # Projection
        trdata  = ccrs.PlateCarree() 
        
        ax = plt.axes(projection= ccrs.PlateCarree())
        ax.outline_patch.set_edgecolor(edgcol2)

        gridl=True
        if gridl:
            # gridlines
            gl = ax.gridlines(draw_labels=True,linewidth=1, color='#585858', alpha=0.2, linestyle='--')
            # grid labels
            #label_style = {'size': 12, 'color': 'black', 'weight': 'bold'}
            label_style = {'size': 12, 'color': '#BDBDBD', 'weight': 'normal'}
            
            gl.xlabel_style = label_style
            gl.xlabels_bottom = False
            gl.xlocator = mticker.FixedLocator(np.arange(-180,180,incrgridlon,dtype=float))
            gl.ylabel_style = label_style
            gl.ylabels_right = False
            gl.ylocator = mticker.FixedLocator(np.arange(-90,90,incrgridlat,dtype=float))

        # Add Coastlines and or plain continents
        if coastC:
            ax.add_feature(ccf.COASTLINE, facecolor='w', edgecolor='none')
        if coastLand:
            ax.add_feature(ccf.LAND, facecolor='w', edgecolor='none')
        if coastL:
            #ax.coastlines(color='#585858',linewidth=1)
             ax.coastlines(color='w',linewidth=1)
        
        ### PLOTS: 
        if typlo=='pcolormesh':
            cs  = plt.pcolormesh(nav_lon, nav_lat, ehonan,cmap=cmap,transform=trdata,norm=norm)
        
        if typlo=='contourf':
            cs  = plt.contourf(nav_lon, nav_lat, ehonan,transform=trdata,levels=levels,norm=norm,cmap=cmap,extend='both')

        # geographical limits
        plt.xlim(xlim)
        plt.ylim(ylim) 
        
        
        
def plotmapMEDWEST_gp(fig3,ax,data2plot,cmap,norm,plto='tmp_plot',gridpts=True,gridptsgrid=False,gridinc=200,gstyle='lightstyle'): 
    
    cs  = ax.pcolormesh(data2plot,cmap=cmap,norm=norm)

    #ax = plt.gca()
    # Remove the plot frame lines. 
    ax.spines["top"].set_visible(False)  
    ax.spines["bottom"].set_visible(False)  
    ax.spines["right"].set_visible(False)  
    ax.spines["left"].set_visible(False)  

    ax.tick_params(axis="both", which="both", bottom="off", top="off",  
                labelbottom="off", labeltop='off',left="off", right="off", labelright="off",labelleft="off")  

    
    if gridpts:
    # show gridpoint on axes
        ax.tick_params(axis="both", which="both", bottom="off", top="off",  
                labelbottom="on", labeltop='off',left="off", right="off", labelright="off",labelleft="on")  
        plto = plto+"_wthgdpts"

    if gridptsgrid:
        lstylegrid=(0, (5, 5)) 
        if (gstyle=='darkstyle'):
            cmap.set_bad('#424242')
            lcolorgrid='w'#"#585858" # "#D8D8D8"
            tcolorgrid='#848484'#"#848484"
            
        if (gstyle=='ddarkstyle'):
            cmap.set_bad('#424242')
            lcolorgrid='w'#"#585858" # "#D8D8D8"
            tcolorgrid='w'#'#848484'#"#848484"
        if (gstyle=='lightstyle'):
            cmap.set_bad('w')
            lcolorgrid="#585858" # "#D8D8D8"
            tcolorgrid='#848484'#"#848484"            

        lalpha=0.2
        lwidthgrid=1.
        #ax = plt.gca()
        ax.xaxis.set_major_locator(mticker.MultipleLocator(gridinc))
        ax.yaxis.set_major_locator(mticker.MultipleLocator(gridinc))   
        ax.tick_params(axis='x', colors=tcolorgrid)
        ax.tick_params(axis='y', colors=tcolorgrid)
        ax.grid(which='major',linestyle=lstylegrid,color=lcolorgrid,alpha=lalpha,linewidth=lwidthgrid)
        #ax.axhline(y=1.,xmin=0, xmax=883,zorder=10,color=lcolorgrid,linewidth=lwidthgrid,linestyle=lstylegrid,alpha=lalpha )
    
    return cs,ax



def plottsts(var1,var2,xl1=0,yl1=0,xl2=-1,yl2=-1,diro='./',namo='plotts.png',dpifig=300):
    if xl2==-1:
        xl2=xl1
    if yl2==-1:
        yl2=yl1
        
    ts1 = var1.isel(x=xl1,y=yl1)
    ts2 = var2.isel(x=xl2,y=yl2)

    fig2 = plt.figure(figsize=([15,8]),facecolor='white')
    
    plt.plot(ts1,color='blue',marker='o')
    plt.plot(ts2,color='k',marker='+')

    plt.show()
    saveplt(plt,fig2,diro,namo,dpifig=dpifig)
    return plt,fig2


def saveplt(fig,diro,namo,dpifig=300):
    fig.savefig(diro+namo, facecolor=fig.get_facecolor(), edgecolor='none',dpi=dpifig,bbox_inches='tight', pad_inches=0)
    plt.close(fig) 

def mycolormap(levbounds,cm_base='Spectral_r',cu='w',co='k',istart=0):
    lmin = levbounds[0]
    lmax = levbounds[1]
    incr = levbounds[2]
    levels = np.arange(lmin,lmax,incr)
    if ( (cm_base=='NCL') | (cm_base=='MJO') | (cm_base=='NCL_NOWI') ):
        nice_cmap = slx.make_SLXcolormap(whichco=cm_base)
    else:
        nice_cmap = plt.get_cmap(cm_base)
    colors = nice_cmap(np.linspace(istart/len(levels),1,len(levels)))[:]
    cmap, norm = from_levels_and_colors(levels, colors, extend='max')
    cmap.set_under(cu)
    cmap.set_over(co)
    return cmap,norm

def make_cmap(colors, position=None, bit=False):
    '''
    make_cmap takes a list of tuples which contain RGB values. The RGB
    values may either be in 8-bit [0 to 255] (in which bit must be set to
    True when called) or arithmetic [0 to 1] (default). make_cmap returns
    a cmap with equally spaced colors.
    Arrange your tuples so that the first color is the lowest value for the
    colorbar and the last is the highest.
    position contains values from 0 to 1 to dictate the location of each color.
    '''
    
    import matplotlib as mpl
    import numpy as np
    bit_rgb = np.linspace(0,1,256)
    if position == None:
        position = np.linspace(0,1,len(colors))
    else:
        if len(position) != len(colors):
            sys.exit("position length must be the same as colors")
        elif position[0] != 0 or position[-1] != 1:
            sys.exit("position must start with 0 and end with 1")
    if bit:
        for i in range(len(colors)):
            colors[i] = (bit_rgb[colors[i][0]],
                         bit_rgb[colors[i][1]],
                         bit_rgb[colors[i][2]])
    cdict = {'red':[], 'green':[], 'blue':[]}
    for pos, color in zip(position, colors):
        cdict['red'].append((pos, color[0], color[0]))
        cdict['green'].append((pos, color[1], color[1]))
        cdict['blue'].append((pos, color[2], color[2]))

    cmap = mpl.colors.LinearSegmentedColormap('my_colormap',cdict,256)
    return cmap



def make_SLXcolormap(reverse=False,whichco='MJO'):
    ''' Define a custom cmap .
    Parameters: 
    * Reverse (default=False). If true, will  create the reverse colormap
    * whichco (default='MJO': which colors to use. For now: only 'MJO', 'NCL', 'NCL_NOWI' available.
    ''' 

    ### colors to include in my custom colormap
    if whichco=='MJO':
        colors_NCLbipo=[(176,17,3,1),(255,56,8,1),(255,196,1,1),(255,255,255,1),(255,255,255,1),(13,176,255,1),(2,88,255,1),(0,10,174,1)]

    if whichco=='NCL':
        colors_NCLbipo=[(11,76,95),(0,97,128),(0,161,191),(0,191,224),(0,250,250),(102,252,252),(153,250,250),(255,255,255),(255,255,255),(252,224,0),(252,191,0),(252,128,0),(252,64,0),(252,33,0),(128,0,0),(0,0,0)]

    if whichco=='NCL_NOWI':
        colors_NCLbipo=[(11,76,95),(0,97,128),(0,161,191),(0,191,224),(0,250,250),(102,252,252),(153,250,250),(255,255,255),(252,224,0),(252,191,0),(252,128,0),(252,64,0),(252,33,0),(128,0,0),(0,0,0)]

    ### Call the function make_cmap which returns my colormap
    my_cmap_NCLbipo = make_cmap(colors_NCLbipo[:], bit=True)
    my_cmap_NCLbipo_r = make_cmap(colors_NCLbipo[::-1], bit=True)
    
    if reverse==True:
        my_cmap_NCLbipo = my_cmap_NCLbipo_r

    return(my_cmap_NCLbipo)


    



def addcolorbar(fig,cs,ax,levbounds,levincr=1,tformat="%.2f",tlabel='',shrink=0.45,facmul=1.,orientation='vertical',tc='k',loc='lower right',wth="15%",bbta=(0.08, -0.1,0.9,0.2)):
    lmin = levbounds[0]
    lmax = levbounds[1]
    incr = levbounds[2]
    levels = np.arange(lmin,lmax,incr)
    cblev = levels[::levincr]
    
    if orientation =='horizontal':
        axins1 = inset_axes(ax,
                        height=wth,  # height : 5%
                            width="50%",
                        bbox_to_anchor=bbta,
                        bbox_transform=ax.transAxes,
                        borderpad=0)

    if orientation =='vertical':
        axins1 = inset_axes(ax,
                        height="50%",  # height : 5%
                            width="2%",
                        loc='center left',
                       borderpad=2)

    cb = fig.colorbar(cs,cax=axins1,
                                    extend='both',                   
                                    ticks=cblev,
                                    spacing='uniform',
                                    orientation=orientation,
                                    )
    
    new_tickslabels = [tformat % i for i in cblev*facmul]
    cb.set_ticklabels(new_tickslabels)
    cb.ax.set_xticklabels(new_tickslabels, rotation=70,size=10,color=tc)
    cb.ax.tick_params(labelsize=10,color=tc) 
    cb.set_label(tlabel,size=14,color=tc)
    
    
    return cb,axins1

def flatexvarname(varna):
    if varna=='sosstsst':
        varname='SST'
        latexvarname=varname
    elif varna=='sossheig':
        varname='SSH'
        latexvarname=varname
    elif varna=='socurloverf':
        varname='curloverf'
        latexvarname="$\zeta/f$"
    else :
        varname=varna
        latexvarname=varna
    return varname,latexvarname

def textunit(varname):
    if ((varname=='SST') | (varname=='SSH')):
        if varname=='SST':
            suffix=" (ºC)"
        if varname=='SSH':
            suffix=" (m)"
    else:
        suffix=""
    return suffix

def textunitfac(varname,faclab):
    if ((faclab=="1")|(faclab=="")):
        if varname=='SST':
            suffix=" (ºC)"
        elif varname=='SSH':
            suffix=" (m)"
        elif varname=='curloverf':
            suffix=""
        elif ((varname=='e1t')|(varname=='e2t')):
            suffix=" (m)"
        else :
            suffix=""
    else :
        if varname=='SST':
            suffix=" ("+faclab+" ºC)"
        elif varname=='SSH':
            if faclab=='10$^{-3}$':
                suffix=" (mm)"    
            elif faclab=='10$^{-2}$':
                suffix=" (cm)"    
            else:
                suffix=" ("+faclab+" m)"
        elif varname=='curloverf':
            suffix=" x("+faclab+")"
        else :
            suffix=" x("+faclab+")"    
    return suffix

def getslope(data,it1,it2,fac=1,tconv=24):
    # tconv conversion from data time freq to days
    from scipy.stats import linregress

    truc1=data*fac
    # regression linear on the log plot from it1 to it2
    resreg1=linregress(np.arange(it1,it2), np.log(truc1.isel(time_counter=slice(it1,it2))))

    # doubling time: td=ln(2)/k where k is the slope of ln(y) = ln(yo) + kt
    slope=(np.log(2)/resreg1.slope)/tconv  # in days
    #print(td1)
    return(slope)


def fxRMSEreg(diff,region=[0,0,0,0]):
    #reg=[x0,x1,y0,y1]; if unrequested then compute over all domain
    if np.array(region).sum()==0:
        region=[0,diff.shape[2]-1,0,diff.shape[1]-1]
    diffreg = diff.isel(x=slice(region[0],region[1]),y=slice(region[2],region[3]))
    diffsqreg = diffreg*diffreg
    diffsqstreg = diffsqreg.stack(z=('x', 'y'))
    RMSEreg = np.sqrt(diffsqstreg.mean(dim='z')).load()
    return RMSEreg


def fillnacorrection(dat):
    dat = dat.where(dat!=0.,-9999.)
    dat = dat.fillna(-9999.)
    dat = dat.where(dat!=-9999.)
    return dat


def stdens(varIN):
    STDens    = varIN.std(dim='e').load()
    STDens    = fillnacorrection(STDens)
    STDensdom = STDens.stack(z=('x', 'y'))
    STDensdom = STDensdom.mean(dim='z').load()
    return STDens,STDensdom

def spavedom(varIN):
    #need to mask data prior to using this.
    STDensdom = varIN.stack(z=('x', 'y'))
    STDensdom = STDensdom.mean(dim='z').load()
    return STDensdom

def spstatsdom(varIN):
    #need to mask data prior to using this.
    #STDensdom = varIN.stack(z=('x', 'y'))
    MINensdom = STDensdom.min(dim='z').load()
    MAXensdom = STDensdom.max(dim='z').load()
    ensdom10p = STDensdom.quantile(0.1,dim='z').load()
    ensdom90p = STDensdom.quantile(0.9,dim='z').load()
    return MINensdom,MAXensdom,ensdom10p,ensdom90p

def definepathsonmachine(machine):
    if machine=='LAP':
        diriprefix ='/Users/leroux/DATA/MEDWEST60_DATA/'

    if machine=='CAL1':
        diriprefix ='/mnt/meom/workdir/lerouste/MEDWEST60/'
        
    if machine=='JZ':
        diriprefix ='/gpfsstore/rech/egi/commun/MEDWEST60/'
        
    maskfile   = diriprefix+'/MEDWEST60-I/MEDWEST60_mask.nc4'
    bathyfile  = diriprefix+'/MEDWEST60-I/MEDWEST60_Bathymetry_v3.3.nc4'
    return diriprefix,maskfile,bathyfile



def saveplt(fig,diro,namo,dpifig=300):
    fig.savefig(diro+namo, facecolor=fig.get_facecolor(),
                edgecolor='none',dpi=dpifig,bbox_inches='tight', pad_inches=0)
    plt.close(fig) 