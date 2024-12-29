# Setting up UnlockPDF for Windows

# Ensure Java is installed
if (-not (Get-Command "java" -ErrorAction SilentlyContinue)) {
    Write-Host "Java is not installed. Installing Java..."
    Invoke-WebRequest -Uri "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe" -OutFile "$env:TEMP\jdk_installer.exe"
    Start-Process -FilePath "$env:TEMP\jdk_installer.exe" -ArgumentList "/s" -Wait
    [System.Environment]::SetEnvironmentVariable("PATH", "$env:PATH;C:\Program Files\Java\jdk-17\bin", [System.EnvironmentVariableTarget]::Machine)
}

# Create working directory
Write-Host "Creating working directory..."
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\UnlockPDF"
Set-Location -Path "$env:USERPROFILE\UnlockPDF"

# Download iText library
Write-Host "Downloading iText PDF library..."
Invoke-WebRequest -Uri "https://github.com/itext/itext7/releases/download/7.2.5/itext7-core-7.2.5.jar" -OutFile "itext7-core-7.2.5.jar"

# Generate Java file
Write-Host "Generating Java source file..."
@"
import javax.swing.*;
import java.awt.*;
import java.awt.dnd.*;
import java.awt.datatransfer.*;
import java.io.*;
import java.nio.file.*;
import java.util.List;

public class UnlockPDF {

    public static void main(String[] args) {
        // Create a JFrame with a centered green square
        JFrame frame = new JFrame("Unlock PDF");
        frame.setSize(400, 400);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new BorderLayout());

        JPanel panel = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                g.setColor(Color.GREEN);
                g.fillRect(50, 50, 300, 300);
                g.setColor(Color.BLACK);
                g.setFont(new Font("Arial", Font.BOLD, 18));
                g.drawString("Drag PDF Here", 140, 220);
            }
        };
        frame.add(panel, BorderLayout.CENTER);

        // Add drag-and-drop functionality
        new DropTarget(panel, new DropTargetListener() {
            @Override
            public void dragEnter(DropTargetDragEvent dtde) {}

            @Override
            public void dragOver(DropTargetDragEvent dtde) {}

            @Override
            public void dropActionChanged(DropTargetDragEvent dtde) {}

            @Override
            public void dragExit(DropTargetEvent dte) {}

            @Override
            public void drop(DropTargetDropEvent dtde) {
                try {
                    dtde.acceptDrop(DnDConstants.ACTION_COPY);
                    Transferable transferable = dtde.getTransferable();
                    List<File> droppedFiles = (List<File>) transferable.getTransferData(DataFlavor.javaFileListFlavor);
                    for (File file : droppedFiles) {
                        if (file.getName().endsWith(".pdf")) {
                            unlockPDF(file);
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        frame.setVisible(true);
    }

    private static void unlockPDF(File pdfFile) {
        try {
            // Use a third-party library like iText for unlocking
            com.itextpdf.kernel.pdf.PdfDocument pdfDoc = new com.itextpdf.kernel.pdf.PdfDocument(
                    new com.itextpdf.kernel.pdf.PdfReader(pdfFile.getAbsolutePath(), 
                            new com.itextpdf.kernel.pdf.ReaderProperties().setPassword(null)),
                    new com.itextpdf.kernel.pdf.PdfWriter(pdfFile.getParent() + "/Unlocked_" + pdfFile.getName())
            );
            pdfDoc.close();
            JOptionPane.showMessageDialog(null, "Unlocked PDF saved as: " + "Unlocked_" + pdfFile.getName());
        } catch (Exception e) {
            JOptionPane.showMessageDialog(null, "Failed to unlock PDF: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
"@ > UnlockPDF.java

# Compile the Java file
Write-Host "Compiling UnlockPDF.java..."
& "javac" -cp ".;itext7-core-7.2.5.jar" UnlockPDF.java

# Create the JAR file
Write-Host "Creating JAR file..."
@"
Main-Class: UnlockPDF
"@ > manifest.txt
& "jar" cvfm UnlockPDF.jar manifest.txt UnlockPDF.class itext7-core-7.2.5.jar

# Run the program
Write-Host "Running UnlockPDF..."
& "java" -jar UnlockPDF.jar
