// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if not exist "%~n0.exe" (
   call %csc% /nologo /r:"Microsoft.VisualBasic.dll" /out:"%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel% 
   )
)

endlocal & exit /b %errorlevel%

*/

// reference  
// https://gallery.technet.microsoft.com/scriptcenter/eeff544a-f690-4f6b-a586-11eea6fc5eb8

using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;
using Microsoft.VisualBasic;


/// Provides functions to capture the active window, and save it to a file. 

public class ScreenCapture
{

    public void CaptureScreenToFile(string filename, ImageFormat format)
    {
        Image img = CaptureScreen();
        img.Save(filename, format);
    }
	
	/// Creates an Image object containing a screen shot of the entire desktop 

    public Image CaptureScreen()
    {
        return CaptureWindow(User32.GetDesktopWindow());
    }
	
	private Image CaptureWindow(IntPtr handle)
    {
        // get te hDC of the target window 
        IntPtr hdcSrc = User32.GetWindowDC(handle);
        // get the size 
        User32.RECT windowRect = new User32.RECT();
        User32.GetWindowRect(handle, ref windowRect);
        int width = windowRect.right - windowRect.left;
        int height = windowRect.bottom - windowRect.top;
        // create a device context we can copy to 
        IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc);
        // create a bitmap we can copy it to, 
        // using GetDeviceCaps to get the width/height 
        IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc, width, height);
        // select the bitmap object 
        IntPtr hOld = GDI32.SelectObject(hdcDest, hBitmap);
        // bitblt over 
        GDI32.BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, GDI32.SRCCOPY);
        // restore selection 
        GDI32.SelectObject(hdcDest, hOld);
        // clean up 
        GDI32.DeleteDC(hdcDest);
        User32.ReleaseDC(handle, hdcSrc);
        // get a .NET image object for it 
        Image img = Image.FromHbitmap(hBitmap);
        // free up the Bitmap object 
        GDI32.DeleteObject(hBitmap);
        return img;
    }


    static String time = "";
	static String file = "kuvakaappaus.png";
	static String directory = "";
    static System.Drawing.Imaging.ImageFormat format = System.Drawing.Imaging.ImageFormat.Png;

	static void parseArguments()
    {
		// Take user arguments
		Console.WriteLine("Anna kuvalle nimi kirjoittamalla sana ja painamalla ENTER");
		Console.WriteLine("Painamalla vain ENTER kuva saa nimeksi päivämäärän");

		String argument = Console.ReadLine();
		if (argument.Equals(""))
		{
			file = directory + time + ".png";
			
		} else
		{
			file = directory + argument + ".png";
			
		} 
	}
	
    public static void Main()
    {
        User32.SetProcessDPIAware();
		ScreenCapture sc = new ScreenCapture();
		const int SW_HIDE = 0;
		const int SW_SHOW = 5;
		
		DateTime now = DateTime.Now;
		time = now.ToString("dd/MM/yyyy HH:mm");
		directory = "./" + now.ToString("MMMM/yyyy") + "/";
		
		try
        {
			if(!Directory.Exists(directory))
			{
				Directory.CreateDirectory(directory);
			}
        }
        catch (Exception e)
        {
            Console.WriteLine("Check if directory is valid " + directory);
            Console.WriteLine(e.ToString());
        }
		
		// Take user arguments
		parseArguments();
		
		// Hide console
		IntPtr handle = User32.GetForegroundWindow();
		User32.ShowWindow(handle, SW_HIDE);
		
        try
        {
			Console.WriteLine("Taking a capture of the whole screen to " + file);
            sc.CaptureScreenToFile(file, format);
        }
        catch (Exception e)
        {
            Console.WriteLine("Check if file path is valid " + file);
            Console.WriteLine(e.ToString());
        }
    }


    /// Helper class containing Gdi32 API functions 

    private class GDI32
    {

        public const int SRCCOPY = 0x00CC0020; // BitBlt dwRop parameter 
        [DllImport("gdi32.dll")]
        public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest,
          int nWidth, int nHeight, IntPtr hObjectSource,
          int nXSrc, int nYSrc, int dwRop);
        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth,
          int nHeight);
        [DllImport("gdi32.dll")]
        public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
        [DllImport("gdi32.dll")]
        public static extern bool DeleteDC(IntPtr hDC);
        [DllImport("gdi32.dll")]
        public static extern bool DeleteObject(IntPtr hObject);
        [DllImport("gdi32.dll")]
        public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
    }


    /// Helper class containing User32 API and kernel32 functions 

    private class User32
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT
        {
            public int left;
            public int top;
            public int right;
            public int bottom;
        }
        [DllImport("user32.dll")]
        public static extern IntPtr GetDesktopWindow();
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowDC(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern IntPtr ReleaseDC(IntPtr hWnd, IntPtr hDC);
        [DllImport("user32.dll")]
        public static extern IntPtr GetWindowRect(IntPtr hWnd, ref RECT rect);
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")]
        public static extern int SetProcessDPIAware();
		
		[DllImport("kernel32.dll")]
		public static extern IntPtr GetConsoleWindow();
		[DllImport("user32.dll")]
		public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
}