// attendance/getAllEmployeesAttendanceForDay.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { date } = req.query;

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .gte('timestamp',`${date} 00:00:00`)
            .lte('timestamp',`${date} 23:59:59`);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ data });
    } else {
        res.setHeader('Allow',['GET']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
