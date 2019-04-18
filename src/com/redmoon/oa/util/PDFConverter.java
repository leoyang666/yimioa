package com.redmoon.oa.util;

import java.io.File;

import com.redmoon.oa.Config;


public class PDFConverter {
    public static boolean convert2PDF(String inputFile, String pdfFile) {
    	/*
    	// 2008服務器上安裝acrobat profession8不行
        ReleaseManager rm = new ReleaseManager();
        IDispatch app;
        try {
            app = new IDispatch(rm, "PDFMakerAPI.PDFMakerApp");
            Object o = app.method("CreatePDF", new Object[] {inputFile, pdfFile});
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            app = null;
            rm.release();
            rm = null;
        }
    	
        File file = new File(pdfFile);
        if (file.exists()) {
            return true;
        }
        return false;        
    	*/
        Config cfg = new Config();
        if (cfg.getBooleanProperty("canConvertToPDF")) {
        	return Word2PDF.convert2PDF(inputFile, pdfFile);
        }
        else {
        	return false;
        }

    }


}
