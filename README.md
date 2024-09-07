# Garuda-AMS

<p align="center">
[![d80SBfV.md.png](https://iili.io/d80SBfV.md.png)](https://freeimage.host/i/d80SBfV)
</p>

## Overview
**Garuda-AMS** is the server-side component of the GARUDA geolocation-based attendance tracking system. Built using Next.js, it handles API requests, data management, and integration with the Flutter mobile application. Developed for Smart India Hackathon 2024, it supports efficient attendance management by processing and storing geolocation data.

### Geolocation-based Automated Recognition and Universal Digital Attendance (GARUDA)

## Problem Statement
**Problem Statement ID: SIH1707**  
Developed for **GAIL Ministry of Petroleum and Natural Gas**  
**Theme**: Miscellaneous  
The goal is to create a backend server that supports geolocation-based attendance tracking, ensuring accurate and scalable data management while reducing manual errors.

## Team Members
- **Punyam Singh**
- **Aayush Arora**
- **Tejaswi M**
- **Aviral Chawla**
- **Kartheek Kotha**
- **Rahul Jayaram**

## Link to Presentation
[Download the GARUDA Presentation](https://drive.google.com/file/d/1hJ7mFn0K7-jhDQJfr9KjZnOag3Mc1QW2/view?usp=drive_link)

## Features

- **API Endpoints:** Provides RESTful APIs for handling attendance data, user management, and office location updates.
- **Real-Time Data Processing:** Processes geolocation data from the Flutter app to record check-ins and check-outs.
- **Data Management:** Stores and manages attendance records, working hours, and user data.
- **Scalability:** Designed to handle increasing user loads with cloud-based infrastructure.
- **Security:** Ensures secure data transmission and storage.

## Technologies Utilized

- **Next.js:** Server-side framework used to build the backend APIs and manage server-side logic.
- **Node.js:** Runtime environment for executing JavaScript code on the server.
- **Supabase:** Provides a scalable database solution for managing attendance data.
- **Cloud Infrastructure:** Ensures scalability and reliability for handling high loads and data storage.

## Screenshots


<div style="white-space: nowrap; overflow-x: auto; overflow-y: hidden; width: 100%; display: inline-block;">
  <img src="https://iili.io/d8Krhu4.th.jpg" alt="d8Krhu4.th.jpg" border="0"  style="width: 15%; height: 30%; margin-right: 20px; display: inline-block;">-
  <img src="https://iili.io/d8KrV8G.th.jpg" alt="d8KrV8G.th.jpg" border="0"  style="width: 15%; height: 30%; margin-right: 20px; display: inline-block;">
  <img src="https://iili.io/d8KrX9f.th.jpg" alt="d8KrX9f.th.jpg" border="0">
  <img src="https://iili.io/d8KrMas.th.jpg" alt="d8KrMas.th.jpg" border="0">
  <img src="https://iili.io/d8Krjwl.th.jpg" alt="d8Krjwl.th.jpg" border="0">
  <img src="https://iili.io/d8Krwt2.th.jpg" alt="d8Krwt2.th.jpg" border="0">
</div>

## How It Works

1. **API Handling:** Manages API requests from the Flutter app to process attendance data.
2. **Data Storage:** Stores geolocation data, attendance records, and user information in the database.
3. **Real-Time Processing:** Updates attendance records in real-time based on data received from the app.
4. **Scalability:** Uses cloud infrastructure to scale with user demand and ensure performance.

## Challenges & Solutions

1. **Location Accuracy:** Inaccurate data could affect attendance records.
   - **Solution:** Implement location validation and smoothing techniques to ensure data accuracy.
   
2. **Data Privacy:** Protecting sensitive attendance data is crucial.
   - **Solution:** Encrypt all data and comply with privacy regulations.

3. **Scalability:** Handling large volumes of data and requests efficiently.
   - **Solution:** Utilize cloud-based solutions with auto-scaling capabilities.

## Impact & Benefits

1. **Increased Efficiency:** Automates data processing and management, reducing manual effort.
2. **Enhanced Accuracy:** Improves the accuracy of attendance records with real-time data handling.
3. **Cost Savings:** Reduces administrative costs and errors associated with manual data management.
4. **Improved Flexibility:** Provides robust support for varied attendance tracking needs and scales with user demands.

## Installation

1. Clone the repository.
2. Set up the Node.js environment.
3. Configure Supabase and other necessary services.

## Contributors

- **Punyam Singh** - Backend Development  
Feel free to contribute to the development and improvement of the Garuda-ams backend.
