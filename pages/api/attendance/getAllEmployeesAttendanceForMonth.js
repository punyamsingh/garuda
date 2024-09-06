// attendance/getAllEmployeesAttendanceForMonth.js

import supabase from '../db';
import { startOfMonth,endOfMonth } from 'date-fns';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { monthStart } = req.query;

        const start = startOfMonth(new Date(monthStart));
        const end = endOfMonth(new Date(monthStart));

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .gte('timestamp',start.toISOString())
            .lte('timestamp',end.toISOString());

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        return res.status(200).json({ data });
    } else {
        res.setHeader('Allow',['GET']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
