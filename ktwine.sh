wget -O li.json https://api01.doax-venusvacation.jp/v1/resource/list
wget https://github.com/Klanly/stevs2019/releases/download/3.0/KT.reg
declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
wget https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
apt install dotnet-sdk-7.0
apt install dotnet-sdk-6.0
dpkg --add-architecture i386
wget -O - https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main'
apt update
apt install --install-recommends winehq-stable
apt-get install -qq wine32 wine64 wine-stable
apt-get install -qq winbind
apt-get install -qq xvfb xdotool x11-utils xterm
curl -sL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks | install /dev/stdin /usr/local/bin/winetricks
wineboot -i
ln -s /root/.wine/drive_c /content/drivec
nohup Xvfb :0 -screen 0 1024x768x16 &
mkdir /content/drivec/zdxvv
wine regedit KT.reg
wine --version