// /api/attendance/getAllAttendanceForEmployee.js

import supabase from '../db';  // Adjust the path based on your project structure

export default async function handler(req,res) {
    const { method,query } = req;

    if (method === 'GET') {
        const { employeeId } = query;

        if (!employeeId || isNaN(parseInt(employeeId,10))) {
            return res.status(400).json({ error: 'Invalid or missing employeeId parameter.' });
        }

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .eq('employee_id',parseInt(employeeId,10));

        if (error) {
            return res.status(500).json({ error: error.message });
        }

        return res.status(200).json(data);
    } else {
        return res.status(405).json({ error: 'Method Not Allowed' });
    }
}
