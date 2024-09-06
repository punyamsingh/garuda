// attendance/createAttendanceRecord.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { employee_id,office_id,event_type,timestamp,mode } = req.body; // event_type can be 'checkin' or 'checkout'

        const { data,error } = await supabase
            .from('attendance')
            .insert([
                {
                    employee_id,
                    office_id,
                    event_type,
                    timestamp,
                    mode,
                },
            ]);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Attendance record created',data });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
