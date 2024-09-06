// attendance/getEmployeeAttendanceForDateRange.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { employee_id,start_date,end_date } = req.query;

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .eq('employee_id',employee_id)
            .gte('timestamp',start_date)
            .lte('timestamp',end_date);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ data });
    } else {
        res.setHeader('Allow',['GET']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
