// /api/attendance/manualCheckIn.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { employee_id,office_id,event_time } = req.body;

        // Validate required fields
        if (!employee_id || !office_id || !event_time) {
            return res.status(400).json({ error: 'employee_id, office_id, and event_time are required.' });
        }

        // Insert manual check-in event into the attendance table
        const { data,error } = await supabase
            .from('attendance')
            .insert([
                {
                    employee_id,
                    office_id,
                    event_type: 'checkin',
                    event_time, // Using event_time as per the schema
                    mode: 'manual', // Marking as manual check-in
                },
            ]);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Manual check-in successful',data });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
