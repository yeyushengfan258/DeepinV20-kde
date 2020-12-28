# Copyright 2020 Alex Woroschilow <alex.woroschilow@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2,
# or (at your option) any later version, as published by the Free
# Software Foundation
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
Summary: DeepinV20-white KDE Theme
Name: DeepinV20-white
Version: 1.0
Release: %(date +"%Y%m%d%H%M")
Source0: %{name}-%{version}-%{release}.tar.gz
Group: Application/Web
License: GPL-2.0
BuildArch: noarch

%define AURORAE_DIR     /usr/share/aurorae/themes
%define SCHEMES_DIR     /usr/share/color-schemes
%define PLASMA_DIR      /usr/share/plasma/desktoptheme
%define LAYOUT_DIR      /usr/share/plasma/layout-templates
%define LOOKFEEL_DIR    /usr/share/plasma/look-and-feel
%define WALLPAPER_DIR   /usr/share/wallpapers
%define KVANTUM_DIR     /usr/share/Kvantum
%define DIR_SDDM        /usr/share/sddm/themes

#%define _unpackaged_files_terminate_build 0

%description
DeepinV20-white kde is a light clean theme for KDE Plasma desktop.

%prep
%setup -q

%install
install -d $RPM_BUILD_ROOT%{AURORAE_DIR}
install -d $RPM_BUILD_ROOT%{SCHEMES_DIR}
install -d $RPM_BUILD_ROOT%{PLASMA_DIR}
install -d $RPM_BUILD_ROOT%{LAYOUT_DIR}
install -d $RPM_BUILD_ROOT%{LOOKFEEL_DIR}
install -d $RPM_BUILD_ROOT%{WALLPAPER_DIR}
install -d $RPM_BUILD_ROOT%{KVANTUM_DIR}
install -d $RPM_BUILD_ROOT%{DIR_SDDM}

cp --recursive ./aurorae/*                            $RPM_BUILD_ROOT%{AURORAE_DIR}
cp --recursive ./color-schemes/*.colors               $RPM_BUILD_ROOT%{SCHEMES_DIR}
cp --recursive ./plasma/desktoptheme/DeepinV20-*      $RPM_BUILD_ROOT%{PLASMA_DIR}
cp --recursive ./plasma/look-and-feel/*               $RPM_BUILD_ROOT%{LOOKFEEL_DIR}
cp --recursive ./wallpaper/*                          $RPM_BUILD_ROOT%{WALLPAPER_DIR}
cp --recursive ./Kvantum/*                            $RPM_BUILD_ROOT%{KVANTUM_DIR}
cp --recursive ./sddm/DeepinV20-*                     $RPM_BUILD_ROOT%{DIR_SDDM}

%files 
%defattr(644,root,root,755)
%dir %{AURORAE_DIR}
%dir %{SCHEMES_DIR}
%dir %{PLASMA_DIR}
%dir %{LAYOUT_DIR}
%dir %{LOOKFEEL_DIR}
%dir %{WALLPAPER_DIR}
%dir %{KVANTUM_DIR}
%dir %{DIR_SDDM}

%{AURORAE_DIR}/*
%{SCHEMES_DIR}/*
%{PLASMA_DIR}/*
%{LOOKFEEL_DIR}/*
%{WALLPAPER_DIR}/*
%{KVANTUM_DIR}/*
%{DIR_SDDM}/*

