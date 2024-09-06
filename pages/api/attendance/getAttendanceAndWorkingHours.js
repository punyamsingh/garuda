// /api/attendance/getAttendanceAndWorkingHours.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { employee_id,date } = req.query;

        // Validate inputs
        if (!employee_id || !date) {
            return res.status(400).json({ error: 'employee_id and date are required.' });
        }

        try {
            // Convert the date to the format YYYY-MM-DD
            const formattedDate = new Date(date).toISOString().split('T')[0];

            // Fetch all check-in and check-out events for the given employee and date
            const { data: attendanceData,error: attendanceError } = await supabase
                .from('attendance')
                .select('event_type, event_time')
                .eq('employee_id',employee_id)
                .gte('event_time',`${formattedDate}T00:00:00Z`)
                .lte('event_time',`${formattedDate}T23:59:59Z`)
                .order('event_time',{ ascending: true });

            if (attendanceError) {
                return res.status(500).json({ error: attendanceError.message });
            }

            // Fetch the total working hours for the given employee and date from the working_hours_data table
            const { data: workingHoursData,error: workingHoursError } = await supabase
                .from('working_hours_data')
                .select('total_hours')
                .eq('employee_id',employee_id)
                .eq('day',formattedDate);

            if (workingHoursError) {
                return res.status(500).json({ error: workingHoursError.message });
            }

            const totalWorkingHours = workingHoursData.length > 0 ? workingHoursData[0].total_hours : 0;

            return res.status(200).json({
                message: 'Attendance and total working hours fetched successfully',
                attendance: attendanceData,
                total_working_hours: totalWorkingHours.toFixed(2),
            });

        } catch (error) {
            return res.status(500).json({ error: 'An error occurred while fetching attendance records.' });
        }
    } else {
        res.setHeader('Allow',['GET']);
        return res.status(405).json({ error: `Method ${req.method} not allowed.` });
    }
}
