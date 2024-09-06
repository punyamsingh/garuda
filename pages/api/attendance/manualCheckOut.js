// attendance/manualCheckOut.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'POST') {
        const { employee_id,office_id,timestamp } = req.body;

        // Insert manual check-out event
        const { data,error } = await supabase
            .from('attendance')
            .insert([
                {
                    employee_id,
                    office_id,
                    event_type: 'checkout',
                    timestamp,
                    mode: 'manual', // Marking as manual check-out
                },
            ]);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ message: 'Manual check-out successful',data });
    } else {
        res.setHeader('Allow',['POST']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
